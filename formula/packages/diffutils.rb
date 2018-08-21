class Diffutils < Package

  desc 'GNU Diffutils is a package of several programs related to finding differences between files'
  homepage 'https://www.gnu.org/software/diffutils/'
  url 'https://ftp.gnu.org/gnu/diffutils/diffutils-${version}.tar.xz'

  release '3.6', crystax: 3

  build_copy 'COPYING'
  build_options copy_installed_dirs: ['bin'],
                gen_android_mk: false


  def build_for_abi(abi, _toolchain,  _release, _options)
    args = ["--prefix=#{install_dir_for_abi(abi)}",
            "--host=#{host_for_abi(abi)}",
            "--disable-silent-rules",
            "--disable-rpath"
           ]

    configure *args
    make
    make 'install'
  end
end
