class Less < Package

  desc "GNU less is a program similar to more, but which allows backward movement in the file as well as forward movement"
  homepage "https://www.gnu.org/software/less/"
  url "https://ftp.gnu.org/gnu/less/less-530.tar.gz"

  release '530', crystax: 4

  depends_on 'ncurses'

  build_copy 'COPYING', 'LICENSE'
  build_options add_deps_to_cflags: true,
                add_deps_to_ldflags: true,
                sysroot_in_cflags: false,
                copy_installed_dirs: ['bin'],
                gen_android_mk: false


  def build_for_abi(abi, _toolchain,  _release, _options)
    args =  [ "--prefix=#{install_dir_for_abi(abi)}",
              "--host=#{host_for_abi(abi)}"
            ]

    configure *args
    make
    make 'install'
  end
end
