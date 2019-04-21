class Yasm < Utility

  desc "Modular BSD reimplementation of NASM"
  homepage "http://yasm.tortall.net/"
  url "https://www.tortall.net/projects/yasm/releases/yasm-${version}.tar.gz"

  release '1.3.0', crystax: 4

  def build_for_platform(platform, release, options)
    install_dir = install_dir_for_platform(platform.name, release)

    args  = platform.configure_args +
            ["--prefix=#{install_dir}",
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
