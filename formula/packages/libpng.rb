class Libpng < Package

  desc "Library for manipulating PNG images"
  homepage "http://www.libpng.org/pub/png/libpng.html"
  url "https://sourceforge.net/projects/libpng/files/libpng16/${version}/libpng-${version}.tar.xz"
  url "https://sourceforge.net/projects/libpng/files/libpng16/older-releases/${version}/libpng-${version}.tar.xz"

  release '1.6.37', crystax: 2

  build_copy 'LICENSE'
  build_options export_ldlibs: '-lz'

  def build_for_abi(abi, _toolchain, release, _options)
    install_dir = install_dir_for_abi(abi)
    args =  [ "--disable-silent-rules",
              "--enable-shared",
              "--enable-static",
              "--disable-werror", # because of _POSIX_SOURCE redefinition
              "--with-pic",
              "--enable-unversioned-links"
            ]
    args << '--enable-arm-neon=api' if abi == 'armeabi-v7a' or abi == 'armeabi-v7a-hard'

    configure *args
    make
    make 'install'

    clean_install_dir abi
    FileUtils.cd("#{install_dir}/lib") do
      vs = v2d(release)
      ['a', 'so'].each { |ext| FileUtils.mv "libpng#{vs}.#{ext}", "libpng.#{ext}" }
    end
  end

  def sonames_translation_table(release)
    { "libpng#{v2d(release)}.so" => 'libpng' }
  end

  def v2d(release)
    release.version.split('.').first(2).join
  end
end
