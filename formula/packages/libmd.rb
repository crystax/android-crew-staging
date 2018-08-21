class Libmd < Package

  desc "This library provides message digest functions found on BSD systems"
  homepage "https://www.hadrons.org/software/libmd/"
  url "https://archive.hadrons.org/software/libmd/libmd-${version}.tar.xz"

  release '1.0.0', crystax: 2

  build_copy 'COPYING'

  def build_for_abi(abi, _toolchain, release, _options)
    args =  [ "--prefix=#{install_dir_for_abi(abi)}",
              "--host=#{host_for_abi(abi)}",
              "--disable-silent-rules",
              "--enable-shared",
              "--enable-static",
              "--with-pic",
              "--with-sysroot"
            ]

    configure *args
    make
    make 'install'

    clean_install_dir abi
  end
end
