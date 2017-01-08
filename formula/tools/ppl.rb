class Ppl < BuildDependency

  desc "Parma Polyhedra Library: numerical abstractions for analysis, verification"
  homepage "http://bugseng.com/products/ppl"
  url "http://bugseng.com/products/ppl/download/ftp/releases/${version}/ppl-${version}.tar.xz"

  release version: '1.2', crystax_version: 1, sha256: { linux_x86_64:   'fff30eab1dab4f7701d3b5b925042be0bbabd24351b4e3f9303efb4378eddef3',
                                                        darwin_x86_64:  '62d2cbc9bcbf1b8426b069d2929e2b714339a5a300ed78cc5323e5f6032bdbda',
                                                        windows_x86_64: '749f1b638fb943f1b9bb5bd6072a70d90c0d225308467952c04e4602915758c2',
                                                        windows:        '98bc42caa279317c2ce6e8af6eab051247172e24ca85a0d568f86be7e938768d'
                                                      }

  depends_on 'gmp'

  def build_for_platform(platform, release, options, host_dep_dirs, _target_dep_dirs)
    install_dir = install_dir_for_platform(platform, release)

    gmp_dir = host_dep_dirs[platform.name]['gmp']

    args = ["--prefix=#{install_dir}",
            "--host=#{platform.configure_host}",
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
