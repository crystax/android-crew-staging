class Libtiff < Package

  desc "TIFF library"
  homepage "http://www.remotesensing.org/libtiff/"
  url "http://download.osgeo.org/libtiff/tiff-${version}.tar.gz"

  release version: '4.0.6', crystax_version: 3

  depends_on 'libjpeg'

  build_copy 'COPYRIGHT'
  build_options use_cxx: true

  def build_for_abi(abi, _toolchain, _release, _host_dep_dirs, target_dep_dirs, _options)
    install_dir = install_dir_for_abi(abi)
    libjpeg_dir = target_dep_dirs['libjpeg']
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
    FileUtils.cd("#{install_dir}/lib") { FileUtils.rm_rf ['pkgconfig'] + Dir['*.la'] }
  end
end
