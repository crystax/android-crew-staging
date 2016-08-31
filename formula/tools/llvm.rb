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

  PYTHON_VER   = '2.7'
  BINUTILS_VER = '2.25'


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
      install_dir = File.join(base_dir, 'install')
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
              "--disable-debugserver"
             ]

      make_flags = ['VERBOSE=1']
      make_flags << 'LIBS=-lmsvcr90' if platform.target_os == 'windows'

      FileUtils.mkdir_p build_dir
      FileUtils.cd(build_dir) do
        system "#{src_dir}/configure", *args
        system 'make', '-j', num_jobs, *make_flags
        system 'make', 'install', *make_flags
      end
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
end
