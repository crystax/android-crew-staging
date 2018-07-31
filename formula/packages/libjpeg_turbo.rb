class LibjpegTurbo < Package

  desc "JPEG image codec that aids compression and decompression"
  name 'libjpeg-turbo'
  homepage "http://www.libjpeg-turbo.org/"
  url "https://downloads.sourceforge.net/project/libjpeg-turbo/${version}/libjpeg-turbo-${version}.tar.gz"

  release '1.5.3'

  build_copy 'LICENSE.md'
  build_libs 'libturbojpeg', 'libjpeg'

  build_options sysroot_in_cflags: false

  def build_for_abi(abi, _toolchain, _release, _options)
    args =  [ "--prefix=#{install_dir_for_abi(abi)}",
              "--host=#{host_for_abi(abi)}",
              "--disable-silent-rules",
              "--enable-shared",
              "--enable-static",
              "--with-pic",
              "--disable-ld-version-script"
            ]
    args << '--without-simd' if abi == 'mips'

    configure *args
    make
    make 'install'

    clean_install_dir abi
  end
end
