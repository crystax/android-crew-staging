class CloogOld < BuildDependency

  desc "Generate code for scanning Z-polyhedra, old version for GCC 4.9"
  homepage "https://www.cloog.org/"
  url "https://www.bastoul.net/cloog/pages/download/cloog-${version}.tar.gz"

  release version: '0.18.0', crystax_version: 1, sha256: { linux_x86_64:   '91c90970dbeb22826369fbc6ff5a3da3af02cc11bad2f0f280f89cb690723adc',
                                                           darwin_x86_64:  '584d99fb0df2d81cbe0b4972a781919719720983d06eddac59eccb2cfd29944b',
                                                           windows_x86_64: '041eb181b0f41e802c6bc6e796d5cb02cec1fd371881ca7876fd12b0560a73e6',
                                                           windows:        '47434090adb4a92786201a61777c188419a2f60c29a5b733abe06a4eeeac5578'
                                                         }

  depends_on 'gmp'
  depends_on 'ppl'
  depends_on 'isl-old'

  def build_for_platform(platform, release, options, host_dep_dirs, _target_dep_dirs)
    install_dir = install_dir_for_platform(platform, release)

    isl_dir = host_dep_dirs[platform.name]['isl-old']
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
