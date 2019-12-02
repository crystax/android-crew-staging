class Mpfr < BuildDependency

  desc "C library for multiple-precision floating-point computations"
  homepage "http://www.mpfr.org/"
  url "http://www.mpfr.org/mpfr-${version}/mpfr-${version}.tar.xz"

  release '3.1.5', crystax: 5

  depends_on 'gmp'

  def build_for_platform(platform, release, options)
    install_dir = install_dir_for_platform(platform.name, release)

    gmp_dir = host_dep_dir(platform.name, 'gmp')

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
