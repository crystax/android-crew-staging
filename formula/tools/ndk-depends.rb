class NdkDepends < Utility

  desc "A small portable program used to dump the dynamic dependencies of a shared library"
  homepage ""

  release version: '1', crystax_version: 1, sha256: { linux_x86_64:   '4fc102d6c631364a079deefe94ad0952c494e3f92bf6dacf3e0a27221b9cb8f4',
                                                      darwin_x86_64:  '9b2b9cf43f463c469c6bca57909b781de38e1e6e68270bbc695cd77e3686acf9',
                                                      windows_x86_64: 'd1395cfd7b81d547e2d0b3d16c70789f9946a40ede876a0c066ce99a6ae1ea09',
                                                      windows:        'a5a630d2e65dd8602e39add85f1809318baaa4a75651623f98872f0ff8e65c93'
                                                    }

  executables 'ndk-depends'

  def prepare_source_code(release, dir, src_name, log_prefix)
  end

  def build_for_platform(platform, release, options, _host_dep_dirs, _target_dep_dirs)
    src_dir = File.join(Build::NDK_HOST_TOOLS_DIR, 'ndk-depends')
    install_dir = File.join(install_dir_for_platform(platform, release), 'bin')
    FileUtils.mkdir_p install_dir

    prog_name = File.join(install_dir, "ndk-depends#{platform.target_exe_ext}")
    build_dir = Dir.pwd
    debug = ''

    build_env['CFLAGS']  += ' -O2 -s -ffunction-sections -fdata-sections'
    build_env['LDFLAGS']  = ''
    build_env['LDFLAGS'] += ' -m32' if platform.target_cpu == 'x86'
    build_env['LDFLAGS'] += ' -Wl,-gc-sections' unless platform.target_os  == 'darwin'

    args = ['-C', src_dir,
            '-f', "#{src_dir}/GNUmakefile",
            '-B',
            "PROGNAME=\"#{prog_name}\"",
            "BUILD_DIR=\"#{build_dir}\"",
            "CC=\"#{platform.cc}\"",
            "CXX=\"#{platform.cxx}\"",
            "STRIP=\"#{platform.strip}\"",
            "DEBUG=#{debug}"
           ]

    system 'make', '-j', num_jobs, *args
  end
end
