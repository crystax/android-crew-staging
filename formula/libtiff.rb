require_relative '../library/utils.rb'
require_relative '../library/build.rb'

class Libtiff < Library

  desc "TIFF library"
  homepage "http://www.remotesensing.org/libtiff/"
  url "http://download.osgeo.org/libtiff/tiff-{version}.tar.gz"

  release version: '4.0.6', crystax_version: 1, sha256: '0'

  depends_on 'libjpeg'
end
