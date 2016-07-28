class Gmp < BuildDependency

  desc "GNU multiple precision arithmetic library"
  homepage "https://gmplib.org/"
  url "https://gmplib.org/download/gmp/gmp-${version}.tar.xz"

  release version: '6.1.1', crystax_version: 1, sha256: { linux_x86_64:   '0',
                                                          darwin_x86_64:  '0',
                                                          windows_x86_64: '0',
                                                          windows:        '0'
                                                        }

  def build_for_platform(platform, release, options, _)
    install_dir = install_dir_for_platform(platform, release)

    args = ["--prefix=#{install_dir}",
            "--host=#{platform.configure_host}",
            "--enable-cxx",
            "--disable-shared"
           ]
    args << 'ABI=32' if platform.target_name == 'windows'

    system "#{src_dir}/configure", *args
    system 'make', '-j', num_jobs
    system 'make', 'check' if options.check? platform
    system 'make', 'install'

    # remove unneeded files before packaging
    FileUtils.cd(install_dir) { FileUtils.rm_rf ['share'] + Dir['lib/*.la'] }
  end
end
