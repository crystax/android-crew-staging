class NdkBase < HostFormula

  desc "Base NDK directory structure, sources, build tools and scripts"
  homepage "https://www.crystax.net"
  url 'https://github.com/crystax/android-platform-ndk.git|git_tag:$(version)_$(crystax_version)'

  release version: '11', crystax_version: 1, sha256: { linux_x86_64:   '0',
                                                       darwin_x86_64:  '0',
                                                       windows_x86_64: '0',
                                                       windows:        '0'
                                                     }

  include Properties

  # todo: fix files list
  TOP_FILES_AND_DIRS = ['Android.mk',
                        'BACKERS.md',
                        'CHANGELOG.md',
                        'CleanSpec.mk',
                        'OWNERS',
                        'README.md',
                        'build',
                        'checkbuild.py',
                        'cmake',
                        'config.py',
                        'crew',
                        'docs',
                        'ndk-build',
                        'ndk-gdb',
                        'ndk-gdb.py',
                        'ndk-which',
                        'tests',
                        'tools'
                       ]

  WIN_FILES = ['crew.cmd', 'ndk-gdb.cmd']

  def release_directory(release)
    File.join(Global::SERVICE_DIR, name, release.version)
  end

  def install_archive(release, archive, platform_name = Global::PLATFORM_NAME, ndk_dir = Global::NDK_DIR)
    rel_dir = release_directory(release)
    FileUtils.mkdir_p rel_dir unless Dir.exists? rel_dir
    prop = get_properties(rel_dir)

    FileUtils.cd(ndk_dir) do
     FileUtils.rm_rf TOP_FILES_AND_DIRS
      FileUtils.rm_rf WIN_FILES if platform_name.start_with? 'windows'
    end
    Utils.unpack archive, ndk_dir

    prop[:installed] = true
    prop[:installed_crystax_version] = release.crystax_version
    save_properties prop, rel_dir

    release.installed = release.crystax_version
  end

  def build(release, options, host_dep_dirs, target_dep_dirs)
    platforms = options.platforms.map { |name| Platform.new(name) }
    puts "Building #{name} #{release} for platforms: #{platforms.map{|a| a.name}.join(' ')}"

    self.num_jobs = options.num_jobs

    # create required directories and download sources
    FileUtils.rm_rf build_base_dir
    puts "= preparing source code"
    prepare_source_code release, File.dirname(src_dir), File.basename(src_dir), ' '
    if options.source_only?
      puts "Only sources were requested, find them in #{src_dir}"
      return
    end

    platforms.each do |platform|
      puts "= building for #{platform.name}"

      base_dir = base_dir_for_platform(platform)
      install_dir = File.join(base_dir, 'install')
      FileUtils.mkdir_p install_dir
      self.log_file = build_log_file(platform)

      FileUtils.cd(src_dir) do
        FileUtils.cp_r TOP_FILES_AND_DIRS, install_dir
        FileUtils.cp WIN_FILES if platform.target_os == 'windows'
      end
      next if options.build_only?

      archive = File.join(Global::CACHE_DIR, archive_filename(release, platform.name))
      Utils.pack archive, install_dir

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
end
