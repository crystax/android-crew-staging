class Make < Utility

  desc "Utility for directing compilation"
  homepage "https://www.gnu.org/software/make/"
  url "https://ftpmirror.gnu.org/make/make-${version}.tar.bz2"

  release version: '3.81', crystax_version: 1, sha256: { linux_x86_64:   '0',
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
    FileUtils.cd(install_dir) { FileUtils.rm_rf(['info', 'man']) }
  end
end
