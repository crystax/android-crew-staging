class NdkStack < Utility

  desc "A ndk-stack utility"
  name 'ndk-stack'
  homepage ""

  release '1', crystax: 4

  def prepare_source_code(release, dir, src_name, log_prefix)
  end

  def build_for_platform(platform, release, options)
    src_dir = File.join(Build::NDK_HOST_TOOLS_DIR, 'ndk-stack')
    install_dir = File.join(install_dir_for_platform(platform.name, release), 'bin')
    binutils_src_dir = File.join(Build::TOOLCHAIN_SRC_DIR, 'binutils', "binutils-#{Build::BINUTILS_VER}")
    binutils_build_dir = File.join(Dir.pwd, 'binutils')
    FileUtils.mkdir_p [install_dir, binutils_build_dir]

    build_env.clear
    build_env['CC']                       = platform.cc
    build_env['CXX']                      = platform.cxx
    build_env['AR']                       = platform.ar
    build_env['RANLIB']                   = platform.ranlib
    build_env['CFLAGS']                   = platform.cflags
    build_env['CXXFLAGS']                 = platform.cxxflags
    build_env['LDFLAGS']                  = ''
    build_env['LDFLAGS']                 += ' -Wl,-gc-sections'                         unless platform.target_os == "darwin"
    build_env['LDFLAGS']                 += ' -m32'                                     if platform.target_cpu == 'x86'
    build_env['PATH']                     = "#{platform.toolchain_path}:#{ENV['PATH']}" #if platform.target_os == 'darwin'
    build_env['MACOSX_DEPLOYMENT_TARGET'] = Build::MACOS_MIN_VER                        if platform.target_os == 'darwin'

    # it's because with use for windows builds gcc 7
    if platform.target_os  == 'windows'
      build_env['CFLAGS'] += ' -Wno-error=implicit-fallthrough -Wno-error=shift-negative-value -Wno-error=pointer-compare'
      build_env['CFLAGS'] += ' -Wno-error=shift-overflow' if platform.target_cpu == 'x86'
    end

    puts "  building binutils"
    build_binutils platform, binutils_src_dir, binutils_build_dir

    puts "  building ndk-stack"
    prog_name = File.join(install_dir, "ndk-stack#{platform.target_exe_ext}")
    debug = ''

    cflags = ["-DHAVE_CONFIG_H",
              "-I#{binutils_build_dir}/binutils",
              "-I#{binutils_src_dir}/binutils",
              "-I#{binutils_build_dir}/bfd",
              "-I#{binutils_src_dir}/bfd",
              "-I#{binutils_src_dir}/include"
             ]

    ldflags = ["#{binutils_build_dir}/binutils/bucomm.o",
               "#{binutils_build_dir}/binutils/version.o",
               "#{binutils_build_dir}/binutils/filemode.o",
               "#{binutils_build_dir}/bfd/libbfd.a",
               "#{binutils_build_dir}/libiberty/libiberty.a"
              ]
    ldflags += ['-ldl', '-lz'] unless platform.target_os  == 'windows'

    build_env['CFLAGS']  += ' ' + cflags.join(' ')
    build_env['LDFLAGS'] += ' ' + ldflags.join(' ')

    args = ['-C', src_dir,
            '-f', "#{src_dir}/GNUmakefile",
            '-B',
            "PROGNAME=\"#{prog_name}\"",
            "BUILD_DIR=\"#{Dir.pwd}\"",
            "CC=\"#{platform.cc}\"",
            "CXX=\"#{platform.cxx}\"",
            "STRIP=\"#{platform.strip}\"",
            "DEBUG=#{debug}"
           ]

    system 'make', '-j', num_jobs, *args
  end

  def build_binutils(platform, src_dir, build_dir)
    args = ["--host=#{platform.configure_host}",
            "--build=#{platform.configure_build}",
            "--disable-nls",
            "--with-bug-report-url=#{Build::BUG_URL}"
           ]

    # In darwin libbfd has to be built with some *linux* target or it won't understand ELF
    # Disable -Werror because binutils uses deprecated functions (e.g. sbrk).
    args += ['--target=arm-linux-androideabi', '--disable-werror'] if platform.target_os == "darwin"

    FileUtils.cd(build_dir) do
      system "#{src_dir}/configure", *args
      system 'make', '-j', num_jobs
    end
  end
end
