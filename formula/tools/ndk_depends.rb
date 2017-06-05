class NdkDepends < Utility

  desc "A small portable program used to dump the dynamic dependencies of a shared library"
  name 'ndk-depends'
  homepage ""

  release version: '1', crystax_version: 1, sha256: { linux_x86_64:   '28f6ac284c0ed03852c6ca26d266d96e676b61c02ff66b362f0d2ec7baee2eb9',
                                                      darwin_x86_64:  'c2e7235574479016ed4c8e4c64ef8e001b1408bcb101a7f3c46f3a60ad3e3fa8',
                                                      windows_x86_64: 'b34e9f7d627f3c81d5db4f5d1fba358a052eec80ec2646efa041094cae1d4344',
                                                      windows:        'b3364122343f548a3482fa46432e1428c44c4b13493eb7faa4b3ce46bb386460'
                                                    }

  def prepare_source_code(release, dir, src_name, log_prefix)
  end

  def build_for_platform(platform, release, options, _host_dep_dirs, _target_dep_dirs)
    src_dir = File.join(Build::NDK_HOST_TOOLS_DIR, 'ndk-depends')
    install_dir = File.join(install_dir_for_platform(platform.name, release), 'bin')
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
