class Llvm < Tool

  desc "LLVM-based toolchain"
  homepage "http://llvm.org/"
  url "toolchain/llvm-${version}"

  release version: '3.6', crystax_version: 1, sha256: { linux_x86_64:   '0',
                                                        darwin_x86_64:  '0',
                                                        windows_x86_64: '0',
                                                        windows:        '0'
                                                      }

  release version: '3.7', crystax_version: 1, sha256: { linux_x86_64:   '0',
                                                        darwin_x86_64:  '0',
                                                        windows_x86_64: '0',
                                                        windows:        '0'
                                                      }

  release version: '3.8', crystax_version: 1, sha256: { linux_x86_64:   '0',
                                                        darwin_x86_64:  '0',
                                                        windows_x86_64: '0',
                                                        windows:        '0'
                                                      }

  build_depends_on 'libedit'

  ARCHIVE_TOP_DIR  = 'toolchains'
  PYTHON_VER   = '2.7'
  BINUTILS_VER = '2.25'

  UNUSED_LLVM_EXECUTABLES = %w{ bugpoint c-index-test clang-check clang-format clang-tblgen lli llvm-bcanalyzer
                                llvm-config llvm-config-host llvm-cov llvm-diff llvm-dsymutil llvm-dwarfdump llvm-extract llvm-ld
                                llvm-mc llvm-nm llvm-mcmarkup llvm-objdump llvm-prof llvm-ranlib llvm-readobj llvm-rtdyld
                                llvm-size llvm-stress llvm-stub llvm-symbolizer llvm-tblgen llvm-vtabledump macho-dump cloog
                                llvm-vtabledump lli-child-target not count FileCheck llvm-profdata obj2yaml yaml2obj verify-uselistorder"
                              }


  include Properties

  def release_directory(release)
    File.join(Global::SERVICE_DIR, name, release.version)
  end

  def install_archive(release, archive, platform_name = Global::PLATFORM_NAME, ndk_dir = Global::NDK_DIR)
    rel_dir = release_directory(release)
    FileUtils.mkdir_p rel_dir unless Dir.exists? rel_dir
    prop = get_properties(rel_dir)

    prebuilt_dir = File.join(Global::NDK_DIR, ARCHIVE_TOP_DIR, "llvm-#{release.version}", 'prebuilt')
    FileUtils.rm_rf File.join(prebuilt_dir, platform_name)
    FileUtils.rm_rf File.join(Global::NDK_DIR, ARCHIVE_TOP_DIR, "llvm-#{release.version}") if Dir["#{prebuilt_dir}/*"].empty?
    Utils.unpack archive, ndk_dir

    prop[:installed] = true
    prop[:installed_crystax_version] = release.crystax_version
    save_properties prop, rel_dir

    release.installed = release.crystax_version
  end

  def build(release, options, host_dep_dirs, _target_dep_dirs)
    platforms = options.platforms.map { |name| Platform.new(name) }
    puts "Building #{name} #{release} for platforms: #{platforms.map{|a| a.name}.join(' ')}"

    self.num_jobs = options.num_jobs

    FileUtils.rm_rf build_base_dir

    platforms.each do |platform|
      puts "= building for #{platform.name}"

      src_dir = File.join(Build::TOOLCHAIN_SRC_DIR, "llvm-#{release.version}", 'llvm')
      binutils_inc_dir = File.join(Build::TOOLCHAIN_SRC_DIR, 'binutils', "binutils-#{BINUTILS_VER}", 'include')

      base_dir = base_dir_for_platform(platform)
      build_dir = File.join(base_dir, 'build')
      install_dir = File.join(base_dir, ARCHIVE_TOP_DIR, "llvm-#{release.version}", 'prebuilt', platform.name)
      self.log_file = build_log_file(platform)

      libedit_dir = host_dep_dirs[platform.name]['libedit']

      prepare_build_env platform, libedit_dir

      args = ["--prefix=#{install_dir}",
              "--host=#{platform.toolchain_host}",
              "--build=#{platform.toolchain_build}",
              "--with-bugurl=https://tracker.crystax.net/projects/ndk",
              "--enable-targets=arm,mips,x86,aarch64",
              "--enable-optimized",
              "--with-binutils-include=#{binutils_inc_dir}",
              "--disable-lldb",
              "--disable-debugserver",
              "--disable-docs"
             ]

      make_flags = ['VERBOSE=1']
      make_flags << 'LIBS=-lmsvcr90' if platform.target_os == 'windows'

      FileUtils.mkdir_p build_dir
      FileUtils.cd(build_dir) do
        system "#{src_dir}/configure", *args
        system 'make', '-j', num_jobs, *make_flags
        system 'make', 'install', *make_flags
      end

      # copy arm_neon_x86.h from GCC
      gcc_src_dir = File.join(Build::TOOLCHAIN_SRC_DIR, 'gcc',  "gcc-#{Toolchain::DEFAULT_GCC.version}")
      FileUtils.cp "#{gcc_src_dir}/gcc/config/i386/arm_neon.h", "#{install_dir}/lib/clang/#{release.version}/include/arm_neon_x86.h"

      # remove unneeded files
      FileUtils.cd(install_dir) do
        FileUtils.rm_rf ['include', 'share']
        FileUtils.cd('lib') do
          FileUtils.rm_rf ['pkgconfig'] + Dir['*.a', '*.la', 'lib[cp]*.so', 'lib[cp]*.dylib', 'B*.so', 'B*.dylib', 'LLVMH*.so', 'LLVMH*.dylib']
        end
        FileUtils.cd('bin') do
          FileUtils.rm_rf UNUSED_LLVM_EXECUTABLES.map { |e| e + platform.target_exe_ext }
        end
      end

      # strip executables?
      # todo: check that exe's already stripped

      FileUtils.cd(File.join(install_dir, 'bin')) do
        # todo: what are these le-tools?
        ['ndk-link', 'ndk-strip', 'ndk-translate'].map{|e| e + platform.target_exe_ext }.each do |f|
          if File.exist? f
            FileUtils.ln_sf f, "le32-none-#{f}"
            FileUtils.ln_sf f, "le64-none-#{f}"
          end
        end

        Dir['lldb*'].select { |f| File.extname(f) == '' }.each { |f| gen_lldb_wrapper f }
        Build::ABI_LIST.each { |abi| gen_analizer_wrappers abi, platform }
      end

      if not options.build_only?
        archive = File.join(Global::CACHE_DIR, archive_filename(release, platform.name))
        puts "= packaging #{archive}"
        Utils.pack archive, base_dir, ARCHIVE_TOP_DIR

        if options.update_shasum?
          release.shasum = { platform.to_sym => Digest::SHA256.hexdigest(File.read(archive, mode: "rb")) }
          update_shasum release, platform
        end

        puts "= installing #{archive}"
        install_archive release, archive, platform.name
      end

      FileUtils.rm_rf base_dir unless options.no_clean?
    end
  end

  def prepare_build_env(platform, libedit_dir)
    cflags  = " -O2 -I#{libedit_dir}/include -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64"
    ldflags = "-L#{libedit_dir}/lib -static-libstdc++ -static-libgcc"

    ldflags += ' -static' if platform.target_os == 'windows'

    if platform.target_os == 'darwin'
      # todo: build more recent toolchains
      # Disable wchar support for libedit since it require recent C++11 support which we don't
      # have yet in used x86_64-apple-darwin-4.9.2 prebuilt toolchain
      cflags  += " -I#{platform.sysroot}/usr/include -DLLDB_EDITLINE_USE_WCHAR=0"
      ldflags += " -L#{platform.sysroot}/usr/lib -Wl,-syslibroot,#{platform.sysroot} -mmacosx-version-min=10.6"
    end

    if platform.target_os == 'windows'
      # lldb doesnt' support python and curses on Windows
      cflags += ' -DLLDB_DISABLE_PYTHON -DLLDB_DISABLE_CURSES'
    else
      python_home = Global::TOOLS_DIR
      cflags  += " -I#{python_home}/include/python#{PYTHON_VER}"
      ldflags += " -L#{python_home}/lib"
      build_env['PYTHONHOME'] = python_home
    end

    cflags += ' ' + platform.cflags

    build_env.clear

    build_env['PATH']           = (platform.target_os == 'windows') ? Build.path : "#{python_home}/bin:#{Build.path}"
    build_env['LANG']           = 'C'
    build_env['CC']             = platform.cc
    build_env['CXX']            = platform.cxx
    build_env['AR']             = platform.ar
    build_env['RANLIB']         = platform.ranlib
    build_env['CFLAGS']         = cflags
    build_env['CXXFLAGS']       = cflags
    build_env['LDFLAGS']        = ldflags
    build_env['REQUIRES_RTTI']  = '1'
    build_env['DARWIN_SYSROOT'] = platform.sysroot if platform.target_os == 'darwin'

    if platform.target_os == 'darwin'
      # from build-llvm.sh:
      #   For compilation LLDB's Objective-C++ sources we need use clang++, since g++ have a bug
      #   not distinguishing between Objective-C call and definition of C++11 lambda:
      #   https://gcc.gnu.org/bugzilla/show_bug.cgi?id=57607
      #   To workaround this, we're using prebuilt clang++
      #   with includes from our g++, to keep binary compatibility of produced code
      # todo:
      #   build and use more modern gcc (5 or 6)
      #   replace hardcoded versions: 4.9.3, 3.7.0
      #
      gcc_dir = Pathname.new(platform.cc).dirname.dirname
      cxx_inc_dir = File.join(gcc_dir, 'include', 'c++', '4.9.3')
      cxx_bits_inc = File.join(cxx_inc_dir, 'x86_64-apple-darwin')
      objcxx = File.join(Build::PLATFORM_PREBUILTS_DIR, 'clang', 'darwin-x86', 'host', 'x86_64-apple-darwin-3.7.0', 'bin', 'clang++')
      build_env['OBJCXX'] = "#{objcxx} -I#{cxx_bits_inc} -I#{cxx_inc_dir}"
    end

    # if platform.target_os == 'windows'
    #   build_env['PATH'] = "#{File.dirname(platform.cc)}:#{ENV['PATH']}"
    #   build_env['RC'] = "x86_64-w64-mingw32-windres -F pe-i386" if platform.target_cpu == 'x86'
    # end
  end

  def gen_lldb_wrapper(file)
    FileUtils.mv file, "#{file}.bin"
    File.open(file, 'w') do |f|
      f.puts '#!/bin/bash'
      f.puts
      f.puts 'HOST_TAG=`dirname $0`/..'
      f.puts 'HOST_TAG=`cd $HOST_TAG && pwd`'
      f.puts 'HOST_TAG=`basename $HOST_TAG`'
      f.puts ''
      f.puts 'PYTHONHOME=`dirname $0`/../../../../../prebuilt/$HOST_TAG'
      f.puts 'PYTHONHOME=`cd $PYTHONHOME && pwd`'
      f.puts 'export PYTHONHOME'
      f.puts
      f.puts "exec `dirname $0`/#{file}.bin \"$@\""
    end
    FileUtils.chmod 'a+x', file
  end

  def gen_analizer_wrappers(abi, platform)
    llvm_target = llvm_target(abi)
    FileUtils.mkdir_p abi
    FileUtils.cd(abi) do
      if platform.target_os == 'windows'
        gen_windows_analizer_wrappers llvm_target
      else
        gen_unix_analizer_wrappers llvm_target
      end
    end
  end

  def gen_unix_analizer_wrappers(llvm_target)
    [{file: 'analyzer', pp: ''}, {file: 'analyzer++', pp: '++'}].each do |e|
      file = e[:file]
      pp = e[:pp]
      File.open(file, 'w') do |f|
        f.puts '#!/bin/bash'
        f.puts
        f.puts "if [ \"$1\" != \"-cc1\" ]; then"
        f.puts "    `dirname $0`/../clang#{pp} -target #{llvm_target} \"$@\""
        f.puts "else"
        f.puts "    \# target/triple already spelled out."
        f.puts "    `dirname $0`/../clang#{pp} \"$@\""
        f.puts "fi"
      end
      FileUtils.chmod 'a+x', file
    end
  end

  def gen_windows_analizer_wrappers(llvm_target)
    [{file: 'analyzer', pp: ''}, {file: 'analyzer++', pp: '++'}].each do |e|
      file = e[:file]
      pp = e[:pp]
      File.open(file, 'w') do |f|
        f.puts '#!/bin/bash'
        f.puts
        f.puts '@echo off'
        f.puts 'if "%1" == "-cc1" goto :L'
        f.puts "%~dp0\\..\\clang#{pp}.exe -target #{llvm_target} %*"
        f.puts 'if ERRORLEVEL 1 exit /b 1'
        f.puts 'goto :done'
        f.puts ':L'
        f.puts 'rem target/triple already spelled out.'
        f.puts '%~dp0\\..\\clang${HOST_EXE} %*'
        f.puts 'if ERRORLEVEL 1 exit /b 1'
        f.puts ':done'
      end
      FileUtils.chmod 'a+x', file
    end
  end

  def llvm_target(abi)
    case abi
    when 'armeabi-v7a', 'armeabi-v7a-hard'
      'armv7-none-linux-androideabi'
    when 'arm64-v8a'
      'aarch64-none-linux-android'
    when 'x86'
      'i686-none-linux-android'
    when 'x86_64'
      'x86_64-none-linux-android'
    when 'mips', 'mips32r6'
      'mipsel-none-linux-android'
    when 'mips64'
      'mips64el-none-linux-android'
    else
      raise "unsupported ABI: #{abi}"
    end
  end
end
