class NdkBase < HostBase

  desc "Base NDK directory structure, sources, build tools and scripts"
  homepage "https://www.crystax.net"
  # todo: use commit? use master branch? something else?
  #       choose somehow between gitlab and github repos
  url 'git@git.crystax.net:android/platform-ndk.git|git_commit:4337aac72f9703d0935ab3aa9ba8433388e0050d'
  url 'https://git.crystax.net/android/platform-ndk.git|git_commit:4337aac72f9703d0935ab3aa9ba8433388e0050d'

  release version: '11', crystax_version: 1, sha256: { linux_x86_64:   '0',
                                                       darwin_x86_64:  '0',
                                                       windows_x86_64: '0',
                                                       windows:        '0'
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
      FileUtils.rm_rf TOP_FILES_AND_DIRS.select { |d| d != 'sources' }
      FileUtils.rm_rf WIN_FILES if platform_name.start_with? 'windows'
      Dir.exist?('sources') and FileUtils.cd('sources') do
        FileUtils.rm_rf ['android', 'cpufeatures', 'host-tools', 'third_party']
        Dir.exist?('crystax') and FileUtils.cd('crystax') do
          FileUtils.rm_rf all_files_cwd - ['libs']
        end
        Dir.exist?('cxx-stl') and FileUtils.cd('cxx-stl') do
          FileUtils.rm_rf ['gabi++', 'llvm-libc++abi', 'stlport', 'system']
          Dir.exist?('gnu-libstdc++') and FileUtils.cd('gnu-libstdc++') do
            # todo: gcc versions?
            FileUtils.rm_rf all_files_cwd - ['4.9', '5', '6']
          end
          Dir.exist?('llvm-libc++') and FileUtils.cd('llvm-libc++') do
             # todo: llvm versions?
            FileUtils.rm_rf all_files_cwd - ['3.6', '3.7', '3.8']
          end
        end
      end
    end
    Utils.unpack archive, Global::NDK_DIR

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

  def all_files_cwd
    Dir['*'] + Dir['.*'] - ['.', '..']
  end
end
