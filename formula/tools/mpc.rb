class Mpc < BuildDependency

  desc "C library for the arithmetic of high precision complex numbers"
  homepage "http://multiprecision.org"
  url "https://ftpmirror.gnu.org/mpc/mpc-${version}.tar.gz"

  release '1.0.3', crystax: 5

  depends_on 'gmp'
  depends_on 'mpfr'

  def build_for_platform(platform, release, options)
    install_dir = install_dir_for_platform(platform.name, release)

    gmp_dir  = host_dep_dir(platform.name, 'gmp')
    mpfr_dir = host_dep_dir(platform.name, 'mpfr')

    args = platform.configure_args +
           ["--prefix=#{install_dir}",
            "--with-gmp=#{gmp_dir}",
            "--with-mpfr=#{mpfr_dir}",
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
