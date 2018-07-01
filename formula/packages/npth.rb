class Npth < Package

  name 'npth'
  desc "The New GNU Portable Threads"
  homepage "https://github.com/gpg/npth"
  url "https://www.gnupg.org/ftp/gcrypt/npth/npth-${version}.tar.bz2"

  release '1.5'

  build_copy 'COPYING.LIB'
  build_libs 'libnpth'

  def build_for_abi(abi, _toolchain,  _release, _host_dep_dirs, _target_dep_dirs, _options)
    install_dir = install_dir_for_abi(abi)

    args =  [ "--prefix=#{install_dir}",
              "--host=#{host_for_abi(abi)}",
              "--disable-silent-rules",
              "--enable-shared",
              "--enable-static",
              "--with-pic",
              "--with-sysroot"
            ]

    system './configure', *args
    system 'make', '-j', num_jobs
    system 'make', 'install'

    clean_install_dir abi, :lib
  end
end
