class Libksba < Package

  desc "A library to access X.509 certificates and CMS data"
  homepage "https://github.com/gpg/libksba"
  url "https://www.gnupg.org/ftp/gcrypt/libksba/libksba-${version}.tar.bz2"

  release '1.3.5', crystax: 2

  depends_on 'libgpg-error'

  build_copy 'COPYING', 'COPYING.GPLv2', 'COPYING.GPLv3', 'COPYING.LGPLv3'
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
