class Libassuan < Package

  desc "Libassuan is a small library implementing the so-called Assuan protocol"
  homepage "https://www.gnupg.org/software/libassuan/index.html"
  url "https://www.gnupg.org/ftp/gcrypt/libassuan/libassuan-${version}.tar.bz2"

  release '2.5.3', crystax: 3

  depends_on 'libgpg-error'

  build_copy 'COPYING','COPYING.LIB'

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

    build_env['GPG_ERROR_CFLAGS']    = "-I#{target_dep_include_dir('libgpg-error')}"
    build_env['GPG_ERROR_LIBS']      = "-L#{target_dep_lib_dir('libgpg-error', abi)} -lgpg-error"
    build_env['GPG_ERROR_MT_CFLAGS'] = build_env['GPG_ERROR_CFLAGS']
    build_env['GPG_ERROR_MT_LIBS']   = "#{build_env['GPG_ERROR_LIBS']} -lpthread"

    configure *args
    make
    make 'install'

    clean_install_dir abi
  end
end
