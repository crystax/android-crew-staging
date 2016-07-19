class Ppl < BuildDependency

  desc "Parma Polyhedra Library: numerical abstractions for analysis, verification"
  homepage "http://bugseng.com/products/ppl"
  url "http://bugseng.com/products/ppl/download/ftp/releases/${version}/ppl-${version}.tar.xz"

  release version: '1.2', crystax_version: 1, sha256: { linux_x86_64:   '0',
                                                        darwin_x86_64:  '0',
                                                        windows_x86_64: '0',
                                                        windows:        '0'
                                                      }

  depends_on 'gmp'

  def build_for_platform(platform, release, options, dep_dirs)
    install_dir = install_dir_for_platform(platform, release)

    gmp_dir = dep_dirs[platform.name]['gmp']

    #build_env['CFLAGS']  += " -I#{gmp_dir}/include"
    #build_env['LDFLAGS'] += " -L#{gmp_dir}/lib"

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
    FileUtils.cd(install_dir) do
      FileUtils.rm_rf ['bin', 'share']
      FileUtils.rm_rf Dir['lib/*.la']
    end
  end
end
