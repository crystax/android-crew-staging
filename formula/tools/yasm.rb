class Yasm < Utility

  desc "Modular BSD reimplementation of NASM"
  homepage "http://yasm.tortall.net/"
  url "https://www.tortall.net/projects/yasm/releases/yasm-${version}.tar.gz"

  release version: '1.3.0', crystax_version: 1, sha256: { linux_x86_64:   '98684483c5a5523108985db022cb1c502e5f947053172ac0e0eda849224f252c',
                                                          darwin_x86_64:  '8a3134da05f5778b60c470ee78fe9e463fb92bb3274c77480c698b81081834b9',
                                                          windows_x86_64: '962a482818a4d38dabddd934e968783ad06a42d662bb5991c88732db7a09fe5c',
                                                          windows:        '577c834049d473cbbe9434494f4c5673ab67985e1c52a7b225d942f7e11990ab'
                                                        }

  executables 'yasm'

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
      FileUtils.rm    Dir['bin/vsyasm*'] + Dir['bin/ytasm*']
    end
  end
end
