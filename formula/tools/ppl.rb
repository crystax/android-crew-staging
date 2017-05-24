class Ppl < BuildDependency

  desc "Parma Polyhedra Library: numerical abstractions for analysis, verification"
  homepage "http://bugseng.com/products/ppl"
  url "http://bugseng.com/products/ppl/download/ftp/releases/${version}/ppl-${version}.tar.xz"

  release version: '1.2', crystax_version: 1, sha256: { linux_x86_64:   '4f43860c31525a86bd5b987c53453e23b9bac12d0207675ebb838f73e5b374c3',
                                                        darwin_x86_64:  'a1cc83df8cf1e00c4969321c8c44456196fff08aea4bec6f6264c7deabd02db9',
                                                        windows_x86_64: '27d3a12ec40bc4de7aba36892ab10364a76d8e19c8d7ab523214c8121b46a7ab',
                                                        windows:        '652de1b95ea413725793bcfde82a5789725c3f4e6062dee9063bef1178f817bc'
                                                      }

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
