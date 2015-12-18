require_relative '../library/utils.rb'
require_relative '../library/build.rb'

class Libjpeg < Library

  desc "JPEG image manipulation library"
  homepage "http://www.ijg.org"
  url "http://www.ijg.org/files/jpegsrc.v{version}.tar.gz"

  release version: '9a', crystax_version: 1, sha256: '0'

  def build_for_abi(abi)
    args =  [ "--prefix=#{install_dir_for_abi(abi)}",
              "--host=#{host_for_abi(abi)}",
              "--enable-shared",
              "--enable-static",
              "--with-pic",
              "--disable-ld-version-script"
            ]

    system './configure', *args
    system 'make'
    system 'make', 'install'
  end
end
