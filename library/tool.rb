require_relative 'platform.rb'
require_relative 'formula.rb'
require_relative 'hostformula.rb'

class Tool < HostFormula

  namespace :host

  ARCHIVE_TOP_DIR = 'prebuilt'

  def build(release, options, host_dep_dirs, target_dep_dirs)
    platforms = options.platforms.map { |name| Platform.new(name) }
    puts "Building #{name} #{release} for platforms: #{platforms.map{|a| a.name}.join(' ')}"

    self.num_jobs = options.num_jobs

    # create required directories and download sources
    FileUtils.rm_rf build_base_dir
    puts "= preparing source code"
    prepare_source_code release, File.dirname(src_dir), File.basename(src_dir), ' '
    if options.source_only?
      puts "Only sources were requested, find them in #{build_base_dir}"
      return
    end

    platforms.each do |platform|
      puts "= building for #{platform.name}"
      #
      base_dir = base_dir_for_platform(platform)
      build_dir = build_dir_for_platform(platform)
      install_dir = install_dir_for_platform(platform, release)
      FileUtils.mkdir_p [build_dir, install_dir]
      self.log_file = build_log_file(platform)
      # prepare standard build environment
      build_env.clear
      build_env['CC']       = platform.cc
      build_env['CXX']      = platform.cxx
      build_env['AR']       = platform.ar
      build_env['RANLIB']   = platform.ranlib
      build_env['CFLAGS']   = platform.cflags
      build_env['CXXFLAGS'] = platform.cxxflags
      build_env['LANG']     = 'C'
      if platform.target_os == 'windows'
        build_env['PATH'] = "#{File.dirname(platform.cc)}:#{ENV['PATH']}"
        build_env['RC'] = "x86_64-w64-mingw32-windres -F pe-i386" if platform.target_cpu == 'x86'
      end
      #
      FileUtils.cd(build_dir) { build_for_platform platform, release, options, host_dep_dirs, target_dep_dirs }
      next if options.build_only?
      #
      archive = cache_file(release, platform.name)
      Utils.pack archive, base_dir, ARCHIVE_TOP_DIR
      #
      if options.update_shasum?
        release.shasum = { platform.to_sym => Digest::SHA256.hexdigest(File.read(archive, mode: "rb")) }
        update_shasum release, platform
      end
      install_archive release, archive, platform.name
      FileUtils.rm_rf base_dir unless options.no_clean?
    end

    if options.no_clean?
      puts "No cleanup, for build artifacts see #{build_base_dir}"
    else
      FileUtils.rm_rf build_base_dir
    end
  end

  def install_dir_for_platform(platform, release)
    File.join base_dir_for_platform(platform), 'prebuilt', platform.name, self.class::INSTALL_DIR_NAME, file_name, release.to_s
  end
end
