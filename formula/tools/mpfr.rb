class Mpfr < BuildDependency

  desc "C library for multiple-precision floating-point computations"
  homepage "http://www.mpfr.org/"
  url "http://www.mpfr.org/mpfr-${version}/mpfr-${version}.tar.xz"

  release version: '3.1.5', crystax_version: 1, sha256: { linux_x86_64:   'a61d81a096919605de2b57d7cf9e3fd97a43a3cd734724787dbec85058e0e6d3',
                                                          darwin_x86_64:  'c6eda1aded776fe730bf77975de21d2660e5c479f3350a212bd0a91793c6822c',
                                                          windows_x86_64: '54112d2cd4ea78f9ba7e8c43c1cceec40aa5503ece9842ec6cd894c016d80d24',
                                                          windows:        '1dd9449d43327f04268bfdb33739b13cb0aafa55f964de6ef26baae6b39da500'
                                                        }

  depends_on 'gmp'

  def build_for_platform(platform, release, options, host_dep_dirs, _target_dep_dirs)
    install_dir = install_dir_for_platform(platform, release)

    gmp_dir = host_dep_dirs[platform.name]['gmp']

    args = ["--prefix=#{install_dir}",
            "--host=#{platform.configure_host}",
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
