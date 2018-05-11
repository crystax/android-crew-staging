class Pinentry < Package

  desc "pinentry is a small collection of dialog programs that allow GnuPG to read passphrases and PIN numbers in a secure manner"
  homepage "https://www.gnupg.org/related_software/pinentry/"
  url "https://www.gnupg.org/ftp/gcrypt/pinentry/pinentry-${version}.tar.bz2"

  release version: '1.1.0', crystax_version: 1

  depends_on 'ncurses'
  depends_on 'libgpg-error'
  depends_on 'libassuan'

  build_copy 'COPYING'
  build_options copy_installed_dirs: ['bin']

  def build_for_abi(abi, _toolchain,  _release, _host_dep_dirs, target_dep_dirs, _options)
    install_dir = install_dir_for_abi(abi)
    ncurses_dir = target_dep_dirs['ncurses']
    libassuan_dir = target_dep_dirs['libassuan']
    libgpg_error_dir = target_dep_dirs['libgpg-error']

    build_env['NCURSES_CFLAGS'] = target_dep_include_dir(ncurses_dir) + '/ncursesw' + ' ' +  target_dep_include_dir(ncurses_dir)
    build_env['NCURSES_LIBS']   = target_dep_lib_dir(ncurses_dir, abi)

    build_env['GPG_ERROR_CFLAGS'] = target_dep_include_dir(libgpg_error_dir)
    build_env['GPG_ERROR_LIBS']   = target_dep_lib_dir(libgpg_error_dir, abi)

    build_env['LIBASSUAN_CFLAGS']  = target_dep_include_dir(libassuan_dir)
    build_env['LIBASSUAN_LIBS']    = target_dep_lib_dir(libassuan_dir, abi)
    build_env['LIBASSUAN_VERSION'] = Formulary.new['target/libassuan'].highest_installed_release.version

    build_env['LIBS']    =  '-lassuan -lgpg-error -lncursesw -ltinfow'
    build_env['CFLAGS']  += ' ' + [build_env['NCURSES_CFLAGS'], build_env['GPG_ERROR_CFLAGS'], build_env['LIBASSUAN_CFLAGS']].join(' ')
    build_env['LDFLAGS'] += ' ' + [build_env['NCURSES_LIBS'], build_env['GPG_ERROR_LIBS'], build_env['LIBASSUAN_LIBS']].join(' ')

    args =  [ "--prefix=#{install_dir}",
              "--host=#{host_for_abi(abi)}",
              "--disable-silent-rules",
              "--disable-rpath",
              "--enable-libsecret",
              "--disable-pinentry-emacs",
              "--disable-inside-emacs",
              "--disable-pinentry-gtk2",
              "--disable-pinentry-gnome3",
              "--disable-pinentry-qt5",
              "--enable-pinentry-tqt",
              "--enable-pinentry-fltk"
            ]

    system './configure', *args
    system 'make', '-j', num_jobs
    system 'make', 'install'
  end
end
