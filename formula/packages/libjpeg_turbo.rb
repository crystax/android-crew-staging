class LibjpegTurbo < Package

  desc "JPEG image codec that aids compression and decompression"
  name 'libjpeg-turbo'
  homepage "https://www.libjpeg-turbo.org/"
  url "https://downloads.sourceforge.net/project/libjpeg-turbo/${version}/libjpeg-turbo-${version}.tar.gz"

  release '1.5.3', crystax: 5

  build_copy 'LICENSE.md'
  build_libs 'libturbojpeg', 'libjpeg'

  build_options sysroot_in_cflags: false

  def build_for_abi(abi, _toolchain, _release, _options)
    args =  [ "--disable-silent-rules",
              "--enable-shared",
              "--enable-static",
              "--with-pic",
              "--disable-ld-version-script"
            ]

    configure *args
    make
    make 'install'

    clean_install_dir abi
  end
end
