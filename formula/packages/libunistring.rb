class Libunistring < Package

  desc "This library provides functions for manipulating Unicode strings and for manipulating C strings according to the Unicode standard"
  homepage "https://www.gnu.org/software/libunistring/"
  url "https://ftp.gnu.org/gnu/libunistring/libunistring-${version}.tar.xz"

  release '0.9.10', crystax: 3

  build_copy 'COPYING', 'COPYING.LIB'

  def build_for_abi(abi, _toolchain, release, _options)
    args =  [ "--disable-silent-rules",
              "--with-pic",
              "--enable-shared",
              "--enable-static",
              "--with-sysroot"
            ]

    configure *args

    set_pthread_in_use_detection_hard 'config.h'

    make
    make 'install'

    clean_install_dir abi
  end
end
