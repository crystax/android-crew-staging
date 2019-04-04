class Wget < Package

  desc "GNU Wget is a free software package for retrieving files using HTTP, HTTPS, FTP and FTPS the most widely-used Internet protocols"
  homepage "https://www.gnu.org/software/wget/"
  url "https://ftp.gnu.org/gnu/wget/wget-${version}.tar.gz"

  release '1.20', crystax: 2

  depends_on 'openssl'
  depends_on 'libunistring'
  depends_on 'libidn2'
  depends_on 'libpcre-old'

  build_copy 'COPYING'
  build_options copy_installed_dirs: ['bin', 'etc'],
                gen_android_mk:      false

  def build_for_abi(abi, _toolchain,  _release, _options)
    args =  [ "--disable-silent-rules",
              "--disable-nls",
              "--with-ssl=openssl",
              "--without-libpsl",
              "--without-metalink",
              "--without-cares"
            ]

    build_env['OPENSSL_CFLAGS'] = "-I#{target_dep_include_dir('openssl')}"
    build_env['OPENSSL_LIBS']   = "-L#{target_dep_lib_dir('openssl', abi)} -lssl -lcrypto"

    build_env['CFLAGS']  += " -I#{target_dep_include_dir('libidn2')}"
    build_env['LDFLAGS'] += " -L#{target_dep_lib_dir('libidn2', abi)} -lunistring"

    configure *args
    make
    make 'install'
  end
end
