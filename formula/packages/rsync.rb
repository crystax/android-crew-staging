class Rsync < Package

  desc "A fast, versatile, remote (and local) file-copying tool"
  homepage "https://rsync.samba.org/"
  url "https://download.samba.org/pub/rsync/src/rsync-${version}.tar.gz"

  release '3.1.3', crystax: 5

  build_copy 'COPYING'
  build_options copy_installed_dirs: ['bin']

  def build_for_abi(abi, _toolchain,  release, _options)
    args = [ '--with-included-popt' ]
    configure *args
    make
    make 'install'
    clean_install_dir abi
  end
end
