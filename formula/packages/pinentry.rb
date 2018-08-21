class Pinentry < Package

  desc "pinentry is a small collection of dialog programs that allow GnuPG to read passphrases and PIN numbers in a secure manner"
  homepage "https://www.gnupg.org/related_software/pinentry/"
  url "https://www.gnupg.org/ftp/gcrypt/pinentry/pinentry-${version}.tar.bz2"

  release '1.1.0', crystax: 3

  depends_on 'ncurses'
  depends_on 'libgpg-error'
  depends_on 'libassuan'

  build_copy 'COPYING'
  build_options copy_installed_dirs: ['bin']

  def build_for_abi(abi, _toolchain,  _release, _options)
    args =  [ "--prefix=#{install_dir_for_abi(abi)}",
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

    build_env['NCURSES_CFLAGS'] = "-I#{target_dep_include_dir('ncurses')}/ncursesw -I#{target_dep_include_dir('ncurses')}"
    build_env['NCURSES_LIBS']   = "-L#{target_dep_lib_dir('ncurses', abi)}"

    build_env['GPG_ERROR_CFLAGS'] = "-I#{target_dep_include_dir('libgpg-error')}"
    build_env['GPG_ERROR_LIBS']   = "-L#{target_dep_lib_dir('libgpg-error', abi)}"

    build_env['LIBASSUAN_CFLAGS']  = "-I#{target_dep_include_dir('libassuan')}"
    build_env['LIBASSUAN_LIBS']    = "-L#{target_dep_lib_dir('libassuan', abi)}"
    build_env['LIBASSUAN_VERSION'] = Formulary.new['target/libassuan'].highest_installed_release.version

    build_env['LIBS']    =  '-lassuan -lgpg-error -lncursesw'
    build_env['CFLAGS']  += ' ' + [build_env['NCURSES_CFLAGS'], build_env['GPG_ERROR_CFLAGS'], build_env['LIBASSUAN_CFLAGS']].join(' ')
    build_env['LDFLAGS'] += ' ' + [build_env['NCURSES_LIBS'], build_env['GPG_ERROR_LIBS'], build_env['LIBASSUAN_LIBS']].join(' ')

    configure *args
    make
    make 'install'
  end
end
