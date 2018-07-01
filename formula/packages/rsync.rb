class Rsync < Package

  desc "A fast, versatile, remote (and local) file-copying tool"
  homepage "https://rsync.samba.org/"
  url "https://download.samba.org/pub/rsync/src/rsync-${version}.tar.gz"

  release '3.1.3'

  build_copy 'COPYING'
  build_options copy_installed_dirs: ['bin']

  def build_for_abi(abi, _toolchain,  release, _host_dep_dirs, _target_dep_dirs, _options)
    install_dir = install_dir_for_abi(abi)
    src_dir = source_directory(release)

    args = %W[ --prefix=#{install_dir}
               --host=#{host_for_abi(abi)}
               --with-included-popt
             ]

    system "#{src_dir}/configure", *args
    system 'make', '-j', num_jobs
    system 'make', 'install'

    clean_install_dir abi, :lib
  end
end
