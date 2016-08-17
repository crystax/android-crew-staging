class Yasm < Utility

  desc "Modular BSD reimplementation of NASM"
  homepage "http://yasm.tortall.net/"
  url "https://www.tortall.net/projects/yasm/releases/yasm-${version}.tar.gz"

  release version: '1.3.0', crystax_version: 1, sha256: { linux_x86_64:   '0',
                                                          darwin_x86_64:  '0',
                                                          windows_x86_64: '0',
                                                          windows:        '0'
                                                        }

  def build_for_platform(platform, release, options, _host_dep_dirs, _target_dep_dirs)
    install_dir = install_dir_for_platform(platform, release)

    args = ["--prefix=#{install_dir}",
            "--host=#{platform.configure_host}",
            "--disable-nls",
            "--disable-rpath"
           ]

    system "#{src_dir}/configure", *args
    system 'make', '-j', num_jobs
    system 'make', 'test' if options.check? platform
    system 'make', 'install'

    # remove unneeded files before packaging
    FileUtils.cd(install_dir) do
      FileUtils.rm_rf ['include', 'lib', 'share']
      FileUtils.rm    ['bin/vsyasm', 'bin/ytasm']
    end
  end
end
