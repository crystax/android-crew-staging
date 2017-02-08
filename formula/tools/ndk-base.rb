class NdkBase < HostBase

  desc "Base NDK directory structure, sources, build tools and scripts"
  homepage "https://www.crystax.net"
  # todo: use commit? use master branch? something else?
  #       choose somehow between gitlab and github repos
  url 'git@git.crystax.net:android/platform-ndk.git|git_commit:dddcaf549291b796bc0467a97b55a1bfcb9c5ac8'
  url 'https://git.crystax.net/android/platform-ndk.git|git_commit:dddcaf549291b796bc0467a97b55a1bfcb9c5ac8'
  #url 'https://github.com/crystax/android-platform-ndk.git|git_branch:crew-development'

  release version: '11', crystax_version: 1, sha256: { linux_x86_64:   '6f0d8a210038fba6431b4a247a87d3869b865991073c648fba56a50ece1f68d9',
                                                       darwin_x86_64:  'd489390c9897e42ef6023dba3c7423ce4fcae01f56e2270c9ee35b4b63da9b43',
                                                       windows_x86_64: 'a82b15ac5ce8b67b84a7e14b9e767fe84cbcdacdc11bb93d1cbc0202630c8849',
                                                       windows:        '442166788025975d472fe3c725df7f8993e6edc9d95721e52f8d05fb4fedb1c8'
                                                     }

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
                        'sources',
                        'tests',
                        'tools'
                       ]

  WIN_FILES = ['crew.cmd', 'ndk-gdb.cmd']

  def install_archive(release, archive, platform_name)
    rel_dir = release_directory(release)
    FileUtils.mkdir_p rel_dir unless Dir.exists? rel_dir
    prop = get_properties(rel_dir)

    FileUtils.cd(Global::NDK_DIR) do
      FileUtils.rm_rf TOP_FILES_AND_DIRS
      FileUtils.rm_rf WIN_FILES if platform_name.start_with? 'windows'
    end
    Utils.unpack archive, Global::NDK_DIR

    prop[:installed] = true
    prop[:installed_crystax_version] = release.crystax_version
    save_properties prop, rel_dir

    release.installed = release.crystax_version
  end

  # def prepare_source_code(release, dir, src_name, log_prefix)
  #   dst_dir = File.join(dir, src_name)
  #   puts "#{log_prefix} coping sources into #{dst_dir}"
  #   FileUtils.mkdir_p dst_dir
  #   FileUtils.cd(Global::NDK_DIR) { FileUtils.cp_r TOP_FILES_AND_DIRS+WIN_FILES, dst_dir }
  # end

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
        FileUtils.cp   WIN_FILES,          install_dir if platform.target_os == 'windows'
      end
      next if options.build_only?

      archive = cache_file(release, platform.name)
      Utils.pack archive, install_dir

      update_shasum release, platform                 if options.update_shasum?
      install_archive release, archive, platform.name if options.install?
      FileUtils.rm_rf base_dir                        if options.clean?
    end

    if options.no_clean?
      puts "No cleanup, for build artifacts see #{build_base_dir}"
    else
      FileUtils.rm_rf build_base_dir
    end
  end
end
