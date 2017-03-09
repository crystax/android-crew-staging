class Isl < BuildDependency

  desc "Integer Set Library for the polyhedral model"
  homepage "http://isl.gforge.inria.fr"
  url "http://isl.gforge.inria.fr/isl-${version}.tar.xz"
  url "https://mirrors.ocf.berkeley.edu/debian/pool/main/i/isl/isl-${version}.orig.tar.xz"

  release version: '0.17.1', crystax_version: 1, sha256: { linux_x86_64:   '4985bf06844c91cc0e56e3e66287c4cd48735775f71febc79eacfb49ddef1b16',
                                                           darwin_x86_64:  'ec0e30ae21d8c7797436c5e0c5b4f1ea5e1f5ad914f236f6831597768a9d0dd3',
                                                           windows_x86_64: '536d1d901f746506b6f4c1f36347d073f089ed5fbf0c4bec7ec23580f77f7cff',
                                                           windows:        'f3ebe9166bb46e810fec068c203ab740c45fd6aef9c8c322b2d8913602e55089'
                                                         }

  depends_on 'gmp'

  def build_for_platform(platform, release, options, host_dep_dirs, _target_dep_dirs)
    install_dir = install_dir_for_platform(platform, release)

    gmp_dir = host_dep_dirs[platform.name]['gmp']

    args = platform.configure_args +
           ["--prefix=#{install_dir}",
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
    FileUtils.cd(install_dir) { FileUtils.rm_rf ['lib/pkgconfig'] + Dir['lib/*.la'] }
  end
end
