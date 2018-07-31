class Libassuan < Package

  desc "Libassuan is a small library implementing the so-called Assuan protocol"
  homepage "https://www.gnupg.org/software/libassuan/index.html"
  url "https://www.gnupg.org/ftp/gcrypt/libassuan/libassuan-${version}.tar.bz2"

  release '2.5.1', crystax: 2

  depends_on 'libgpg-error'

  build_copy 'COPYING','COPYING.LIB'
  build_options add_deps_to_cflags: true,
                add_deps_to_ldflags: true

  def build_for_abi(abi, _toolchain,  _release, _options)
    args =  [ "--prefix=#{install_dir_for_abi(abi)}",
              "--host=#{host_for_abi(abi)}",
              "--disable-silent-rules",
              "--enable-shared",
              "--enable-static",
              "--disable-doc",
              "--with-pic",
              "--with-sysroot"
            ]

    configure *args
    make
    make 'install'

    clean_install_dir abi
  end
end
