class GnuPg < Package

  name 'gnu-pg'
  desc "GnuPG is a complete and free implementation of the OpenPGP standard as defined by RFC4880 (also known as PGP)"
  homepage "https://www.gnupg.org"
  url "https://www.gnupg.org/ftp/gcrypt/gnupg/gnupg-${version}.tar.bz2"

  release '2.2.7', crystax: 3

  depends_on 'sqlite'
  depends_on 'npth'
  depends_on 'ncurses'
  depends_on 'readline'
  depends_on 'gnu-tls'
  depends_on 'libgpg-error'
  depends_on 'libassuan'
  depends_on 'libksba'
  depends_on 'libgcrypt'
  depends_on 'pinentry'

  build_copy 'COPYING'
  build_options use_standalone_toolchain: true,
                copy_installed_dirs: ['bin', 'libexec', 'sbin', 'share'],
                gen_android_mk:      false


  def build_for_abi(abi, toolchain,  _release, _host_dep_dirs, target_dep_dirs, _options)
    install_dir = install_dir_for_abi(abi)

    build_env['NPTH_VERSION']     = Formulary.new['target/npth'].highest_installed_release.version
    build_env['SQLITE3_CFLAGS']   = ' '
    build_env['SQLITE3_LIBS']     = ' '
    build_env['LIBGNUTLS_CFLAGS'] = ' '
    build_env['LIBGNUTLS_LIBS']   = ' '

    build_env['GPG_ERROR_VERSION'] = Formulary.new['target/libgpg-error'].highest_installed_release.version
    build_env['LIBASSUAN_VERSION'] = Formulary.new['target/libassuan'].highest_installed_release.version
    build_env['KSBA_VERSION']      = Formulary.new['target/libksba'].highest_installed_release.version
    build_env['LIBGCRYPT_VERSION'] = Formulary.new['target/libksba'].highest_installed_release.version

    gnupg_libs  = '-lgcrypt -lksba -lassuan -lgpg-error'
    gnutls_libs = '-lgnutls -lp11-kit -lidn2 -lunistring -lnettle -lhogweed -lffi -lgmp -lz'

    build_env['LIBS']        = gnupg_libs + ' '  + gnutls_libs + ' -lreadline -lncursesw -lnpth -lsqlite3'
    build_env['PATH']        = Build.path

    args =  [ "--prefix=#{install_dir}",
              "--host=#{host_for_abi(abi)}",
              "--disable-silent-rules",
              "--disable-doc",
              "--enable-tofu",
              "--disable-ldap",
              "--disable-rpath",
              "--disable-nls",
            ]

    system './configure', *args
    system 'make', '-j', num_jobs
    system 'make', 'install'

    FileUtils.cd(install_dir) { FileUtils.rm_rf 'share/doc' }
  end
end
