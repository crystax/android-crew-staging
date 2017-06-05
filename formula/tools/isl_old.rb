class IslOld < BuildDependency

  desc "Integer Set Library for the polyhedral model, old version for GCC 4.9"
  name 'isl-old'
  homepage "http://isl.gforge.inria.fr"
  url "http://isl.gforge.inria.fr/isl-${version}.tar.gz"

  release version: '0.11.1', crystax_version: 1, sha256: { linux_x86_64:   'da5f3fdff32d4ce08984e8dae28d3b6ca9accf096d8a3bea5972b1a3417f6e87',
                                                           darwin_x86_64:  'b77b80be15cac363b8950c4e3ba03d61b20833c30245d1b64fe5ab5373bb20bf',
                                                           windows_x86_64: '4a740b626c3654148f985468cce63395c58e4701384d7e803484bfb13f9b597e',
                                                           windows:        '2a3f164b3478b31caa4cd198f15e1874430d4257368fb9e44514a6e8985880cb'
                                                         }

  depends_on 'gmp'

  def build_for_platform(platform, release, options, host_dep_dirs, _target_dep_dirs)
    install_dir = install_dir_for_platform(platform.name, release)

    gmp_dir = host_dep_dirs[platform.name]['gmp']

    # without -O2 there is uresolved reference to ffs()
    build_env['CFLAGS'] += ' -O2' if platform.target_os == 'windows'

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
