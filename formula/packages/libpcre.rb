class Libpcre < Package

  desc 'Perl Compatible Regular Expressions'
  homepage 'https://www.pcre.org'
  url 'https://ftp.pcre.org/pub/pcre/pcre2-${version}.tar.gz'

  release '10.31'

  build_copy 'COPYING'
  build_options copy_installed_dirs: ['bin', 'include', 'lib']
  build_libs 'libpcre2-8', 'libpcre2-posix'

  def build_for_abi(abi, _toolchain, release, _host_dep_dirs, _target_dep_dirs, _options)
    install_dir = install_dir_for_abi(abi)

    args =  [ "--prefix=#{install_dir}",
              "--host=#{host_for_abi(abi)}",
              "--disable-silent-rules",
              "--enable-shared",
              "--enable-static",
              "--with-pic",
              "--with-sysroot"
            ]

    system './configure', *args
    system 'make', '-j', num_jobs
    system 'make', 'install'

    clean_install_dir abi, :lib
  end
end
