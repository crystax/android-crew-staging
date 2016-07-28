class Libtiff < Package

  desc "TIFF library"
  homepage "http://www.remotesensing.org/libtiff/"
  url "http://download.osgeo.org/libtiff/tiff-${version}.tar.gz"

  release version: '4.0.6', crystax_version: 1, sha256: '0'

  depends_on 'libjpeg'

  build_copy 'COPYRIGHT'
  build_options use_cxx: true

  def build_for_abi(abi, _toolchain, _release, dep_dirs)
    install_dir = install_dir_for_abi(abi)
    libjpeg_dir = dep_dirs['libjpeg']
    args = [ "--prefix=#{install_dir}",
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

    system './configure', *args
    system 'make', '-j', num_jobs
    system 'make', 'install'

    # clean lib dir before packaging
    FileUtils.cd("#{install_dir}/lib") do
      FileUtils.rm_rf 'pkgconfig'
      FileUtils.rm Dir['*.la']
    end
  end
end
