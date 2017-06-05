class NdkStack < Utility

  desc "A ndk-stack utility"
  name 'ndk-stack'
  homepage ""

  release version: '1', crystax_version: 1, sha256: { linux_x86_64:   '955ed00fa1b315c9550ab0fac7defce5af0ca994a6ccf3aa3c43c1c467792356',
                                                      darwin_x86_64:  '8061238750eebc02fba0e09e69ba60313b7813ee1b132e78c129d7312e7d16df',
                                                      windows_x86_64: '8141efe48691c68d7f4837ffb2e935639fd42c723b9961cd2e8e0c1fe0e717fe',
                                                      windows:        '23f5b1467759cbe3f0dd35d5e01d97f2dba042f00d2b46a5aee4a738d2686c15'
                                                    }

  def prepare_source_code(release, dir, src_name, log_prefix)
  end

  def build_for_platform(platform, release, options, _host_dep_dirs, _target_dep_dirs)
    src_dir = File.join(Build::NDK_HOST_TOOLS_DIR, 'ndk-stack')
    install_dir = File.join(install_dir_for_platform(platform.name, release), 'bin')
    binutils_src_dir = File.join(Build::TOOLCHAIN_SRC_DIR, 'binutils', "binutils-#{Build::BINUTILS_VER}")
    binutils_build_dir = File.join(Dir.pwd, 'binutils')
    FileUtils.mkdir_p [install_dir, binutils_build_dir]

    build_env.clear
    build_env['LANG']     = 'C'
    build_env['CC']       = platform.cc
    build_env['CXX']      = platform.cxx
    build_env['AR']       = platform.ar
    build_env['RANLIB']   = platform.ranlib
    build_env['CFLAGS']   = platform.cflags
    build_env['CXXFLAGS'] = platform.cxxflags
    build_env['LDFLAGS']  = ''
    build_env['LDFLAGS'] += ' -Wl,-gc-sections' unless platform.target_os == "darwin"
    build_env['LDFLAGS'] += ' -m32' if platform.target_cpu == 'x86'
    build_env['PATH']     = "#{platform.toolchain_path}:#{ENV['PATH']}" #if platform.target_os == 'darwin'

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

    build_env['CFLAGS']  += ' ' + cflags.join(' ')
    build_env['LDFLAGS'] += ' ' + ldflags.join(' ')
    build_env['LDFLAGS'] += ' -ldl -lz' unless platform.target_os  == 'windows'

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
