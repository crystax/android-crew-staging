class Diffutils < Package

  desc 'GNU Diffutils is a package of several programs related to finding differences between files'
  homepage 'https://www.gnu.org/software/diffutils/'
  url 'https://ftp.gnu.org/gnu/diffutils/diffutils-${version}.tar.xz'

  release '3.6', crystax: 2

  build_copy 'COPYING'
  build_options copy_installed_dirs: ['bin'],
                gen_android_mk: false


  def build_for_abi(abi, _toolchain,  _release, _host_dep_dirs, _target_dep_dirs, _options)
    install_dir = install_dir_for_abi(abi)
    args = ["--prefix=#{install_dir}",
            "--host=#{host_for_abi(abi)}",
            "--disable-silent-rules",
            "--disable-rpath"
           ]

    system './configure', *args
    system 'make', '-j', num_jobs
    system 'make', 'install'
  end
end
