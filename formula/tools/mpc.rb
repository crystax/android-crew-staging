class Mpc < BuildDependency

  desc "C library for the arithmetic of high precision complex numbers"
  homepage "http://multiprecision.org"
  url "https://ftpmirror.gnu.org/mpc/mpc-${version}.tar.gz"

  release version: '1.0.3', crystax_version: 1, sha256: { linux_x86_64:   'c0b4629625a692d8ef79cd5c21aef77e326960e1aff6f1d167d4630b2f68441f',
                                                          darwin_x86_64:  '0',
                                                          windows_x86_64: '41863c0455aec6921a18a801a84ed1ae0a53a53984de4a6f02c75a7499dd07f2',
                                                          windows:        'e5ae5d26c2ed15bc0c5e2556fe5c1a6d7982c118edb9d44fc33a52c77e6de48a'
                                                        }

  depends_on 'gmp'
  depends_on 'mpfr'

  def build_for_platform(platform, release, options, host_dep_dirs, _target_dep_dirs)
    install_dir = install_dir_for_platform(platform, release)

    gmp_dir  = host_dep_dirs[platform.name]['gmp']
    mpfr_dir = host_dep_dirs[platform.name]['mpfr']

    args = ["--prefix=#{install_dir}",
            "--host=#{platform.configure_host}",
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
