class Cloog < BuildDependency

  desc "Generate code for scanning Z-polyhedra"
  homepage "https://www.cloog.org/"
  url "https://www.bastoul.net/cloog/pages/download/cloog-${version}.tar.gz"

  release '0.18.4', crystax: 3

  depends_on 'gmp'
  depends_on 'ppl'
  depends_on 'isl'

  def build_for_platform(platform, release, options, host_dep_dirs, _target_dep_dirs)
    install_dir = install_dir_for_platform(platform.name, release)

    isl_dir = host_dep_dirs[platform.name]['isl']
    gmp_dir = host_dep_dirs[platform.name]['gmp']

    args = platform.configure_args +
           ["--prefix=#{install_dir}",
            "--with-isl-prefix=#{isl_dir}",
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
    FileUtils.cd(install_dir) { FileUtils.rm_rf ['bin', 'lib/cloog-isl', 'lib/isl', 'lib/pkgconfig'] + Dir['lib/*.la'] }
  end
end
