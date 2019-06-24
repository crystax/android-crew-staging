class IslOld < BuildDependency

  desc "Integer Set Library for the polyhedral model, old version for GCC 4.9"
  name 'isl-old'
  homepage "http://isl.gforge.inria.fr"
  url "http://isl.gforge.inria.fr/isl-${version}.tar.gz"

  release '0.11.1', crystax: 4

  depends_on 'gmp'

  def build_for_platform(platform, release, options)
    install_dir = install_dir_for_platform(platform.name, release)

    gmp_dir = host_dep_dir(platform.name, 'gmp')

    # without -O2 there is uresolved reference to ffs()
    build_env['CFLAGS'] += ' -O2' if platform.target_os == 'windows'

    args = platform.configure_args +
           ["--prefix=#{install_dir}",
            "--with-gmp-prefix=#{gmp_dir}",
            "--disable-shared",
            "--disable-silent-rules",
            "--with-sysroot"
           ]

    system "#{src_dir}/configure", *args
    system 'make', '-j', num_jobs
    system 'make', 'check' if options.check? platform
    system 'make', 'install'

    # remove unneeded files before packaging
    FileUtils.cd(install_dir) { FileUtils.rm_rf ['lib/pkgconfig'] + Dir['lib/*.la'] }
  end
end
