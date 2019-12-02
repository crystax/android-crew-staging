class Libksba < Package

  desc "A library to access X.509 certificates and CMS data"
  homepage "https://github.com/gpg/libksba"
  url "https://www.gnupg.org/ftp/gcrypt/libksba/libksba-${version}.tar.bz2"

  release '1.3.5', crystax: 6

  depends_on 'libgpg-error'

  build_copy 'COPYING', 'COPYING.GPLv2', 'COPYING.GPLv3', 'COPYING.LGPLv3'
  build_options add_deps_to_cflags: true,
                add_deps_to_ldflags: true

  def build_for_abi(abi, _toolchain,  _release, _options)
    args =  [ "--disable-silent-rules",
              "--enable-shared",
              "--enable-static",
              "--disable-doc",
              "--with-pic",
              "--with-sysroot"
            ]

    build_env['GPG_ERROR_CFLAGS'] = "-I#{target_dep_include_dir('libgpg-error')}"
    build_env['GPG_ERROR_LIBS']   = "-L#{target_dep_lib_dir('libgpg-error', abi)} -lgpg-error"

    configure *args
    make
    make 'install'

    clean_install_dir abi
  end
end
