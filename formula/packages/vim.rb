class Vim < Package

  desc 'Vim is a highly configurable text editor built to make creating and changing any kind of text very efficient'
  homepage 'https://github.com/vim/vim'
  url 'https://github.com/vim/vim/archive/v${version}.tar.gz'

  release version: '8.0.1486', crystax_version: 3

  depends_on 'ncurses'

  build_copy 'README.txt'
  build_options sysroot_in_cflags:   false,
                copy_installed_dirs: ['bin', 'share'],
                gen_android_mk:      false

  def build_for_abi(abi, _toolchain, _release, _host_dep_dirs, target_dep_dirs, _options)
    install_dir = install_dir_for_abi(abi)
    ncurses_dir = target_dep_dirs['ncurses']

    args =  ["--prefix=#{install_dir}",
             "--host=#{host_for_abi(abi)}",
             "--disable-darwin",
             "--enable-gui=no",
             "--disable-nls",
             "--with-tlib=ncurses"
            ]

    build_env['CFLAGS']  += " -I#{ncurses_dir}/include"
    build_env['LDFLAGS'] += " -L#{ncurses_dir}/libs/#{abi}"
    build_env['LIBS']     = '-lncursesw'

    set_vim_cv
    system './configure', *args
    unset_vim_cv

    system 'make', '-j', num_jobs
    system 'make', 'install'

    # remove unneeded files
    FileUtils.rm_rf "#{install_dir}/share/man"
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
