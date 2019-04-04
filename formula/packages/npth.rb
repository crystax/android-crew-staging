class Npth < Package

  name 'npth'
  desc "The New GNU Portable Threads"
  homepage "https://github.com/gpg/npth"
  url "https://www.gnupg.org/ftp/gcrypt/npth/npth-${version}.tar.bz2"

  release '1.6', crystax: 3

  build_copy 'COPYING.LIB'
  build_libs 'libnpth'

  def build_for_abi(abi, _toolchain,  _release, _options)
    args =  [ "--disable-silent-rules",
              "--enable-shared",
              "--enable-static",
              "--with-pic",
              "--with-sysroot"
            ]

    configure *args
    make
    make 'install'

    clean_install_dir abi
  end
end
