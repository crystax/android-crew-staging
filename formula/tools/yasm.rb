class Yasm < Utility

  desc "Modular BSD reimplementation of NASM"
  homepage "http://yasm.tortall.net/"
  url "https://www.tortall.net/projects/yasm/releases/yasm-${version}.tar.gz"

  release version: '1.3.0', crystax_version: 1, sha256: { linux_x86_64:   '50ca79de60f26329c4174251a453fe9a14e48260a264561b5c19a98d89f833bb',
                                                          darwin_x86_64:  '0',
                                                          windows_x86_64: 'fb6a22f37563db350af7c3cb9f7ab1f087e5c7a6da6396119e33299794cbac0a',
                                                          windows:        '11a768ffa075b53244ea7b74b5ee46605ff64af1616d45c1b9904a9bcd8f0000'
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
