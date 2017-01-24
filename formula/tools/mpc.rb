class Mpc < BuildDependency

  desc "C library for the arithmetic of high precision complex numbers"
  homepage "http://multiprecision.org"
  url "https://ftpmirror.gnu.org/mpc/mpc-${version}.tar.gz"

  release version: '1.0.3', crystax_version: 1, sha256: { linux_x86_64:   'd17b9b0f15eb2e1ec476896275dfe5004315ddd7d9731becd03d22eb0310083f',
                                                          darwin_x86_64:  '8d8784bbda78af0e9d40a31bb712883e72532aa5988acd032ee81607c355dd8c',
                                                          windows_x86_64: '4966c1fb5bc5c1f8b055f26a1b7aa6ce30a90234f6b45a1dab6381d65bf8a8ef',
                                                          windows:        '464db801947350e8aca7ab2059154b31687fe870f5021f4b9f1409ca55eb43a5'
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
