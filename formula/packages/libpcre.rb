class Libpcre < Package

  desc 'Perl Compatible Regular Expressions'
  homepage 'https://www.pcre.org'
  url 'https://ftp.pcre.org/pub/pcre/pcre2-${version}.tar.gz'

  release '10.31'

  build_libs 'libpcre2-8', 'libpcre2-posix'
  build_copy 'LICENCE'
  build_options copy_installed_dirs: ['bin', 'include', 'lib']

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
