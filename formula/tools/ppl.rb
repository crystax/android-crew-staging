class Ppl < BuildDependency

  desc "Parma Polyhedra Library: numerical abstractions for analysis, verification"
  homepage "http://bugseng.com/products/ppl"
  url "http://bugseng.com/products/ppl/download/ftp/releases/${version}/ppl-${version}.tar.xz"

  release '1.2', crystax: 3

  depends_on 'gmp'

  def build_for_platform(platform, release, options, host_dep_dirs, _target_dep_dirs)
    install_dir = install_dir_for_platform(platform.name, release)

    gmp_dir = host_dep_dirs[platform.name]['gmp']

    args = platform.configure_args +
           ["--prefix=#{install_dir}",
            "--with-gmp=#{gmp_dir}",
	    "--without-java",
	    "--disable-ppl_lcdd",
            "--disable-ppl_lpsol",
            "--disable-ppl_pips",
            "--disable-shared",
            "--disable-silent-rules",
            "--disable-documentation",
            "--with-sysroot"
           ]

    system "#{src_dir}/configure", *args
    system 'make', '-j', num_jobs
    system 'make', 'check' if options.check? platform
    system 'make', 'install'

    # remove unneeded files before packaging
    FileUtils.cd(install_dir) { FileUtils.rm_rf ['bin', 'share'] + Dir['lib/*.la'] }
  end
end
