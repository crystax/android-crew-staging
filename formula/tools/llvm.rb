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
    cflags  = platform.cflags + " -O2 -I#{libedit_dir}/include -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64"
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
      cflags  += " -I#{Global::TOOLS_DIR}/include/python#{PYTHON_VER}"
      ldflags += " -L#{Global::TOOLS_DIR}/lib"
    end

    #w_cflags  = "-O2 -I#{libedit_dir}/include -DDISABLE_FUTIMENS -I#{platform.sysroot}/usr/include -DLLDB_EDITLINE_USE_WCHAR=0 -I#{Global::TOOLS_DIR}/include/python#{PYTHON_VER} -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64 -isysroot #{platform.sysroot} -mmacosx-version-min=10.6 -DMACOSX_DEPLOYMENT_TARGET=10.6"
    #w_ldflags = "-L#{libedit_dir}/lib -static-libstdc++ -static-libgcc -L#{platform.sysroot}/usr/lib -L#{Global::TOOLS_DIR}/lib -Wl,-syslibroot,#{platform.sysroot} -mmacosx-version-min=10.6"

    build_env.clear

    build_env['PATH']          = ENV['PATH']
    build_env['LANG']          = 'C'
    build_env['CC']            = platform.cc
    build_env['CXX']           = platform.cxx
    build_env['AR']            = platform.ar
    build_env['RANLIB']        = platform.ranlib
    build_env['CFLAGS']        = cflags
    build_env['CXXFLAGS']      = cflags
    build_env['LDFLAGS']       = ldflags
    build_env['REQUIRES_RTTI'] = '1'

    # if platform.target_os == 'windows'
    #   build_env['PATH'] = "#{File.dirname(platform.cc)}:#{ENV['PATH']}"
    #   build_env['RC'] = "x86_64-w64-mingw32-windres -F pe-i386" if platform.target_cpu == 'x86'
    # end
  end
end
