class Mpfr < BuildDependency

  desc "C library for multiple-precision floating-point computations"
  homepage "http://www.mpfr.org/"
  url "http://www.mpfr.org/mpfr-${version}/mpfr-${version}.tar.xz"

  release version: '3.1.5', crystax_version: 1, sha256: { linux_x86_64:   'bef3856aa8e27fc26dcf450ea4a0aadff38ac6d90a03e01e3f6eb566a4dc64cd',
                                                          darwin_x86_64:  'c6eda1aded776fe730bf77975de21d2660e5c479f3350a212bd0a91793c6822c',
                                                          windows_x86_64: '0e3220b88a1d842a04393a49549a00aac3e7760d3b7e480cf428a8a0b7729767',
                                                          windows:        'e662f69f330c4c2df6859eb67932a344fb24858d3f3e8b582fa3d64664815f35'
                                                        }

  depends_on 'gmp'

  def build_for_platform(platform, release, options, host_dep_dirs, _target_dep_dirs)
    install_dir = install_dir_for_platform(platform, release)

    gmp_dir = host_dep_dirs[platform.name]['gmp']

    args = platform.configure_args +
           ["--prefix=#{install_dir}",
            "--with-gmp=#{gmp_dir}",
            "--disable-shared",
            "--disable-silent-rules",
            "--with-sysroot"
           ]

    system "#{src_dir}/configure", *args
    system 'make', '-j', num_jobs
    system 'make', 'check' if options.check? platform
    system 'make', 'install'

    # remove unneeded files before packaging
    FileUtils.cd(install_dir) { FileUtils.rm_rf ['share'] + Dir['lib/*.la'] }
  end
end
