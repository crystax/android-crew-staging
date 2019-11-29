class Vim < Package

  desc 'Vim is a highly configurable text editor built to make creating and changing any kind of text very efficient'
  homepage 'https://github.com/vim/vim'
  url 'https://github.com/vim/vim/archive/v${version}.tar.gz'

  release '8.1.1456', crystax: 2

  depends_on 'ncurses'

  build_copy 'README.txt'
  build_options build_outside_source_tree: false,
                sysroot_in_cflags:   false,
                add_deps_to_cflags:  true,
                add_deps_to_ldflags: true,
                copy_installed_dirs: ['bin', 'share'],
                gen_android_mk:      false

  def build_for_abi(abi, _toolchain, _release, _options)
    args =  ["--disable-darwin",
             "--enable-gui=no",
             "--disable-nls",
             "--with-tlib=ncurses"
            ]

    set_vim_cv
    configure *args
    unset_vim_cv

    make
    make 'install'

    FileUtils.rm_rf "#{install_dir_for_abi(abi)}/share/man"
  end

  def set_vim_cv
    build_env['vim_cv_bcopy_handles_overlap']   = 'yes'
    build_env['vim_cv_getcwd_broken']           = 'no'
    build_env['vim_cv_memcpy_handles_overlap']  = 'yes'
    build_env['vim_cv_memmove_handles_overlap'] = 'yes'
    build_env['vim_cv_stat_ignores_slash']      = 'yes'
    build_env['vim_cv_terminfo']                = 'yes'
    build_env['vim_cv_toupper_broken']          = 'no'
    build_env['vim_cv_tty_group']               = 'world'
    build_env['vim_cv_tgetent']                 = 'zero'
  end

  def unset_vim_cv
    build_env.delete('vim_cv_bcopy_handles_overlap')
    build_env.delete('vim_cv_getcwd_broken')
    build_env.delete('vim_cv_memcpy_handles_overlap')
    build_env.delete('vim_cv_memmove_handles_overlap')
    build_env.delete('vim_cv_stat_ignores_slash')
    build_env.delete('vim_cv_terminfo')
    build_env.delete('vim_cv_toupper_broken')
    build_env.delete('vim_cv_tty_group')
  end
end
