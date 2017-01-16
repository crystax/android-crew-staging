class Isl < BuildDependency

  desc "Integer Set Library for the polyhedral model"
  homepage "http://isl.gforge.inria.fr"
  url "http://isl.gforge.inria.fr/isl-${version}.tar.xz"
  url "https://mirrors.ocf.berkeley.edu/debian/pool/main/i/isl/isl-${version}.orig.tar.xz"

  release version: '0.17.1', crystax_version: 1, sha256: { linux_x86_64:   '4bdfe888e49bca326419eb574495ad768b9fc463ab8f643c81d2032bc94d05aa',
                                                           darwin_x86_64:  'e528165b1b621a386ebb02eb8dc7eb6f1ccf0577d2364cc5836e6e6fab8f6244',
                                                           windows_x86_64: '1623ef9fae794d3cfd5413d6efb3d48b787f254c64b777000ffa71d8cf50dbdf',
                                                           windows:        '5c7f2bea64a91e635ae9cd10050530c49ebb95957d2451b23b4fab9b16f39dae'
                                                         }

  depends_on 'gmp'

  def build_for_platform(platform, release, options, host_dep_dirs, _target_dep_dirs)
    install_dir = install_dir_for_platform(platform, release)

    gmp_dir = host_dep_dirs[platform.name]['gmp']

    args = ["--prefix=#{install_dir}",
            "--host=#{platform.configure_host}",
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
