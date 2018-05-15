class Less < Package

  desc "GNU less is a program similar to more, but which allows backward movement in the file as well as forward movement"
  homepage "https://www.gnu.org/software/less/"
  url "https://ftp.gnu.org/gnu/less/less-530.tar.gz"

  release version: '530', crystax_version: 3

  depends_on 'ncurses'

  build_copy 'COPYING', 'LICENSE'
  build_options copy_installed_dirs: ['bin'],
                sysroot_in_cflags: false,
                gen_android_mk: false


  def build_for_abi(abi, _toolchain,  _release, _host_dep_dirs, target_dep_dirs, _options)
    install_dir = install_dir_for_abi(abi)
    ncurses_dir = target_dep_dirs['ncurses']

    args =  [ "--prefix=#{install_dir}",
              "--host=#{host_for_abi(abi)}"
            ]

    build_env['CFLAGS']  += " -I#{ncurses_dir}/include"
    build_env['LDFLAGS'] += " -L#{ncurses_dir}/libs/#{abi}"
    build_env['LIBS']    = "-lncurses"

    system './configure', *args
    system 'make', '-j', num_jobs
    system 'make', 'install'
  end
end
