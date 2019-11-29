class Libjpeg < Package

  desc "JPEG image manipulation library"
  homepage "https://www.ijg.org"
  url "https://www.ijg.org/files/jpegsrc.v${version}.tar.gz"

  release '9c', crystax: 5

  build_copy 'README'

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
