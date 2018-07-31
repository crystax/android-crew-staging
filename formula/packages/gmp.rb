class Gmp < Package

  desc "GNU multiple precision arithmetic library"
  homepage "https://gmplib.org/"
  url "https://gmplib.org/download/gmp/gmp-${version}.tar.xz"

  release '6.1.2', crystax: 2

  build_copy 'COPYING', 'COPYING.LESSERv3', 'COPYINGv2', 'COPYINGv3'
  build_libs 'libgmp', 'libgmpxx'
  build_options use_cxx: true,
                ldflags_in_c_wrapper: true

  def build_for_abi(abi, _toolchain, _release, _options)
    args =  [ "--prefix=#{install_dir_for_abi(abi)}",
              "--host=#{host_for_abi(abi)}",
              "--disable-silent-rules",
              "--enable-cxx",
              "--enable-shared",
              "--enable-static",
              "--with-pic"
            ]
    args << "--disable-assembly" if abi == 'mips64'

    build_env['CXXFLAGS'] += ' -lgnustl_shared'

    configure *args
    make
    make 'install'

    clean_install_dir abi
  end
end
