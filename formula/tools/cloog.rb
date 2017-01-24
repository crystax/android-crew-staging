class Cloog < BuildDependency

  desc "Generate code for scanning Z-polyhedra"
  homepage "https://www.cloog.org/"
  url "https://www.bastoul.net/cloog/pages/download/cloog-${version}.tar.gz"

  release version: '0.18.4', crystax_version: 1, sha256: { linux_x86_64:   '15ff75e68672f0ffeed9f65e219c59609969b5d0c66c9ae5706d04c9949a0775',
                                                           darwin_x86_64:  'e92d846ba6f93078259a6455edaa789b87347a6dbca6a77964752a8558f609d1',
                                                           windows_x86_64: '8b8fa2fe501469423d19522ac3a0a3026484abbef296b447582c94b9dac48130',
                                                           windows:        'd598fde21e96070680b1d395ff7a7e378ea0fce0aa0dcb49819982598e9755ed'
                                                         }

  depends_on 'gmp'
  depends_on 'ppl'
  depends_on 'isl'

  def build_for_platform(platform, release, options, host_dep_dirs, _target_dep_dirs)
    install_dir = install_dir_for_platform(platform, release)

    isl_dir = host_dep_dirs[platform.name]['isl']
    gmp_dir = host_dep_dirs[platform.name]['gmp']

    args = ["--prefix=#{install_dir}",
            "--host=#{platform.configure_host}",
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
