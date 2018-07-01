class Libmd < Package

  desc "This library provides message digest functions found on BSD systems"
  homepage "https://www.hadrons.org/software/libmd/"
  url "https://archive.hadrons.org/software/libmd/libmd-${version}.tar.xz"

  release '1.0.0'

  build_copy 'COPYING'

  def build_for_abi(abi, _toolchain, release, _host_dep_dirs, _target_dep_dirs, _options)
    install_dir = install_dir_for_abi(abi)

    args =  [ "--prefix=#{install_dir}",
              "--host=#{host_for_abi(abi)}",
              "--disable-silent-rules",
              "--enable-shared",
              "--enable-static",
              "--with-pic",
              "--with-sysroot"
            ]

    system './configure', *args
    system 'make', '-j', num_jobs
    system 'make', 'install'

    clean_install_dir abi, :lib
  end
end
