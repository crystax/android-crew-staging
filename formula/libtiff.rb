require_relative '../library/utils.rb'
require_relative '../library/build.rb'

class Libtiff < Package

  desc "TIFF library"
  homepage "http://www.remotesensing.org/libtiff/"
  url "http://download.osgeo.org/libtiff/tiff-${version}.tar.gz"

  release version: '4.0.6', crystax_version: 1, sha256: '0'

  depends_on 'libjpeg'

  build_copy 'COPYRIGHT'
  build_options use_cxx: true

  def build_for_abi(abi, _toolchain, _release, dep_dirs)
    libjpeg_dir = dep_dirs['libjpeg']
    args = [ "--prefix=#{install_dir_for_abi(abi)}",
             "--host=#{host_for_abi(abi)}",
             "--enable-shared",
             "--enable-static",
             "--with-pic",
             "--with-jpeg-include-dir=#{libjpeg_dir}/include",
             "--with-jpeg-lib-dir=#{libjpeg_dir}/libs/#{abi}",
             "--disable-jbig",
             "--disable-lzma",
             "--enable-cxx"
           ]

    build_env['CFLAGS'] << ' -mthumb' if abi =~ /^armeabi/

    system './configure', *args
    system 'make', '-j', num_jobs
    system 'make', 'install'
  end
end
