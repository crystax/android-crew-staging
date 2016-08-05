require_relative 'platform.rb'
require_relative 'formula.rb'

class Tool < Formula

  namespace :host

  ARCHIVE_TOP_DIR = 'prebuilt'

  def install(r = releases.last)
    release = find_release(r)
    file = archive_filename(release)

    cachepath = download_archive(file, sha256_sum(release))

    puts "unpacking archive"
    install_archive release, cachepath
  end

  def build(release, options, host_dep_dirs, target_dep_dirs)
    platforms = options.platforms.map { |name| Platform.new(name) }
    puts "Building #{name} #{release} for platforms: #{platforms.map{|a| a.name}.join(' ')}"

    @num_jobs = options.num_jobs

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
      @log_file = build_log_file(platform)
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
      archive = File.join(Global::CACHE_DIR, archive_filename(release, platform.name))
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

  def build_base_dir
    File.join Build::BASE_HOST_DIR, file_name
  end

  def src_dir
    File.join build_base_dir, 'src'
  end

  def base_dir_for_platform(platform)
    File.join build_base_dir, platform.name
  end

  def build_dir_for_platform(platform)
    File.join base_dir_for_platform(platform), 'build'
  end

  def install_dir_for_platform(platform, release)
    File.join base_dir_for_platform(platform), 'prebuilt', platform.name, self.class::INSTALL_DIR_NAME, file_name, release.to_s
  end

  def build_log_file(platform)
    File.join base_dir_for_platform(platform), 'build.log'
  end

  def archive_filename(release, platform_name = Global::PLATFORM_NAME)
    "#{file_name}-#{release}-#{platform_name}.tar.xz"
  end

  def sha256_sum(release)
    release.shasum(Global::PLATFORM_NAME.gsub(/-/, '_').to_sym)
  end

  def update_shasum(release, platform)
    ver = release.version
    cxver = release.crystax_version
    sum = release.shasum(platform.to_sym)
    release_regexp = /^[[:space:]]*release[[:space:]]+version:[[:space:]]+'#{ver}',[[:space:]]+crystax_version:[[:space:]]+#{cxver}/
    platform_regexp = /#{platform.to_sym}:/
    lines = []
    state = :copy
    File.foreach(path) do |l|
      case state
      when :updated
        lines << l
      when :copy
        if  l !~ release_regexp
          lines << l
        else
          if l !~ platform_regexp
            state = :updating
            lines << l
          else
            state = :updated
            lines << l.gsub(/'[[:xdigit:]]+'/, "'#{sum}'")
          end
        end
      when :updating
        if l !~ platform_regexp
          lines << l
        else
          state = :updated
          lines << l.gsub(/'[[:xdigit:]]+'/, "'#{sum}'")
        end
      else
        raise "in formula #{File.basename(file_name)} bad state #{state} on line: #{l}"
      end
    end

    File.open(path, 'w') { |f| f.puts lines }
  end
end
