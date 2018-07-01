class Libunistring < Package

  desc "This library provides functions for manipulating Unicode strings and for manipulating C strings according to the Unicode standard"
  homepage "https://www.gnu.org/software/libunistring/"
  url "http://ftp.gnu.org/gnu/libunistring/libunistring-0.9.8.tar.xz"

  release '0.9.8', crystax: 4

  build_copy 'COPYING', 'COPYING.LIB'

  def build_for_abi(abi, _toolchain, _release, _host_dep_dirs, _target_dep_dirs, _options)
    install_dir = install_dir_for_abi(abi)

    args =  [ "--prefix=#{install_dir}",
              "--host=#{host_for_abi(abi)}",
              "--disable-silent-rules",
              "--with-pic",
              "--enable-shared",
              "--enable-static",
              "--with-sysroot"
            ]

    system './configure', *args

    set_pthread_in_use_detection_hard 'config.h'

    system 'make', '-j', num_jobs
    system 'make', 'install'

    clean_install_dir abi, :lib
  end
end
