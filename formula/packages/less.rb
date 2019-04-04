class Less < Package

  desc "GNU less is a program similar to more, but which allows backward movement in the file as well as forward movement"
  homepage "https://www.gnu.org/software/less/"
  url "https://ftp.gnu.org/gnu/less/less-530.tar.gz"

  release '530', crystax: 6

  depends_on 'ncurses'

  build_copy 'COPYING', 'LICENSE'
  build_options sysroot_in_cflags: false,
                copy_installed_dirs: ['bin'],
                gen_android_mk: false


  def build_for_abi(abi, _toolchain,  _release, _options)
    configure
    make
    make 'install'
  end
end
