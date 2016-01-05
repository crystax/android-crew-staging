class Libpng < Library

  desc "Library for manipulating PNG images"
  homepage "http://www.libpng.org/pub/png/libpng.html"
  url "http://sourceforge.net/projects/libpng/files/libpng16/${version}/libpng-${version}.tar.xz"

  release version: '1.6.19', crystax_version: 1, sha256: '0'

  build_options export_ldlibs: '-lz'
  build_libs 'libpng'

  def build_for_abi(abi, _toolchain, _release, _dep_dirs)
    args =  [ "--prefix=#{install_dir_for_abi(abi)}",
              "--host=#{host_for_abi(abi)}",
              "--enable-shared",
              "--enable-static",
              "--enable-werror",
              "--with-pic",
              "--enable-unversioned-links"
            ]
    args << '--enable-arm-neon=api' if abi == 'armeabi-v7a' or abi == 'armeabi-v7a-hard'

    build_env['CFLAGS'] << ' -mthumb' if abi =~ /^armeabi/

    system './configure', *args
    system 'make', '-j', num_jobs
    system 'make', 'install'
  end
end
