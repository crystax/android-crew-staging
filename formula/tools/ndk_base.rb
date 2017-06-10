class NdkBase < HostBase

  desc "Base NDK directory structure, sources, build tools and scripts"
  name 'ndk-base'
  homepage "https://www.crystax.net"
  # todo: use commit? use master branch? something else?
  #       choose somehow between gitlab and github repos
  url 'git@git.crystax.net:android/platform-ndk.git|git_commit:5fadce6d67b108a6b00162d56abdfdadad554e53'
  url 'https://git.crystax.net/android/platform-ndk.git|git_commit:5fadce6d67b108a6b00162d56abdfdadad554e53'

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

  UNIX_FILES = ['crew', 'ndk-build', 'ndk-gdb']
  WIN_FILES = UNIX_FILES.map { |f| "#{f}.cmd" }

  # why to copy compiler-rt from llvm-3.6?
  # compiler-rt -> ../../../../../toolchain/llvm-3.6/compiler-rt
  # todo: decide with compiler-rt
  CRYSTAX_VENDORS = ['freebsd', 'libkqueue', 'libpwq', 'musl'].map { |d| File.join(Build::VENDOR_SRC_DIR, d) }

  def install_archive(release, archive, platform_name)
    # disable warnings since ndk-base archive contains symlinks
    Global::set_options(['-W'])
    super release, archive, platform_name
  end

  def code_directory(_release, _platform_name)
    Global::NDK_DIR
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

    FileUtils.cd(src_dir) do
      crystax_vendors = 'sources/crystax/vendor'
      crystax_tests   = 'sources/crystax/tests'
      FileUtils.mkdir [crystax_vendors, crystax_tests]
      FileUtils.cp_r CRYSTAX_VENDORS, crystax_vendors
      FileUtils.cp_r File.join(Build::PLATFORM_DIR,   'bionic/tests'),   File.join(crystax_tests, 'bionic')
      FileUtils.cp_r File.join(Build::VENDOR_SRC_DIR, 'libkqueue/test'), File.join(crystax_tests, 'libkqueue')
      FileUtils.cp_r File.join(Build::VENDOR_SRC_DIR, 'libpwq/testing'), File.join(crystax_tests, 'libpwq')
      FileUtils.cp_r File.join(Build::VENDOR_SRC_DIR, 'openpts'),        File.join(crystax_tests, 'openpts')
    end
    FileUtils.rm Dir.glob("#{src_dir}/**/.git")

    platforms.each do |platform|
      puts "= building for #{platform.name}"

      base_dir = base_dir_for_platform(platform.name)
      install_dir = File.join(base_dir, 'install')
      FileUtils.mkdir_p install_dir
      self.log_file = build_log_file(platform.name)

      FileUtils.cd(src_dir) do
        FileUtils.cp_r TOP_FILES_AND_DIRS, install_dir
        FileUtils.cp (platform.target_os == 'windows') ? WIN_FILES : UNIX_FILES, install_dir
      end
      next if options.build_only?
      write_file_list install_dir, platform.name

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
