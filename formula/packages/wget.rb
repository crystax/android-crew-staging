class Wget < Package

  desc "GNU Wget is a free software package for retrieving files using HTTP, HTTPS, FTP and FTPS the most widely-used Internet protocols"
  homepage "https://www.gnu.org/software/wget/"
  url "http://ftp.gnu.org/gnu/wget/wget-${version}.tar.gz"

  release '1.19.5', crystax: 2

  depends_on 'openssl'
  depends_on 'libunistring'
  depends_on 'libidn2'
  depends_on 'libpcre'

  build_copy 'COPYING'
  build_options copy_installed_dirs: ['bin', 'etc'],
                gen_android_mk:      false

  def build_for_abi(abi, _toolchain,  _release, _host_dep_dirs, target_dep_dirs, _options)
    install_dir = install_dir_for_abi(abi)
    openssl_dir = target_dep_dirs['openssl']
    libunistring_dir = target_dep_dirs['libunistring']
    libidn2_dir = target_dep_dirs['libidn2']
    libpcre_dir = target_dep_dirs['libpcre']

    build_env['OPENSSL_CFLAGS'] = "-I#{openssl_dir}/include"
    build_env['OPENSSL_LIBS']   = "-L#{openssl_dir}/libs/#{abi} -lssl -lcrypto"
    build_env['PCRE_CFLAGS']    = "-I#{libpcre_dir}/include"
    build_env['PCRE_LIBS']      = "-L#{libpcre_dir}/libs/#{abi} -lpcre2-8"

    build_env['CFLAGS']  += " -I#{openssl_dir}/include -I#{libunistring_dir}/include -I#{libidn2_dir}/include -I#{libpcre_dir}/include"
    build_env['LDFLAGS'] += " -L#{openssl_dir}/libs/#{abi} -L#{libunistring_dir}/libs/#{abi} -L#{libidn2_dir}/libs/#{abi} -L#{libpcre_dir}/libs/#{abi}"

    args =  [ "--prefix=#{install_dir}",
              "--host=#{host_for_abi(abi)}",
              "--disable-silent-rules",
              "--disable-nls",
              "--with-ssl=openssl",
              "--without-libpsl",
              "--without-metalink",
              "--without-cares"
            ]

    system './configure', *args
    system 'make', '-j', num_jobs
    system 'make', 'install'
  end
end
