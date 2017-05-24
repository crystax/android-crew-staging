class Cloog < BuildDependency

  desc "Generate code for scanning Z-polyhedra"
  homepage "https://www.cloog.org/"
  url "https://www.bastoul.net/cloog/pages/download/cloog-${version}.tar.gz"

  release version: '0.18.4', crystax_version: 1, sha256: { linux_x86_64:   'e27213d578982f41e67246fcd25581959a467d4dea66fa4d4c7f007b4a779731',
                                                           darwin_x86_64:  'e92d846ba6f93078259a6455edaa789b87347a6dbca6a77964752a8558f609d1',
                                                           windows_x86_64: 'e1ef66f459ff5bbdfab28969c252d882f90baad282f3b06d7ed6fa4b61e41995',
                                                           windows:        '638a64e58790ebc4cdbf4153a0cd360d3e2151d4693d10e9e76d3b2f825b2d7d'
                                                         }

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
