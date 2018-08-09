class LibpcreOld < Package

  name 'libpcre-old'
  desc 'Perl Compatible Regular Expressions'
  homepage 'https://www.pcre.org'
  url 'https://ftp.pcre.org/pub/pcre/pcre-${version}.tar.gz'

  release '8.42'

  build_libs 'libpcre', 'libpcrecpp', 'libpcreposix'
  build_copy 'LICENCE'
  build_options use_cxx: true,
                copy_installed_dirs: ['bin', 'include', 'lib']

  def build_for_abi(abi, _toolchain, release, _options)
    args =  [ "--prefix=#{install_dir_for_abi(abi)}",
              "--host=#{host_for_abi(abi)}",
              "--disable-silent-rules",
              "--enable-shared",
              "--enable-static",
              "--enable-utf",
              "--with-pic",
              "--with-sysroot"
            ]

    build_env['LDFLAGS'] += ' -lgnustl_shared'

    configure *args
    make
    make 'install'

    clean_install_dir abi
  end
end
