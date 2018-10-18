class Libtiff < Package

  desc "TIFF library"
  homepage "http://www.libtiff.org"
  url "http://download.osgeo.org/libtiff/tiff-${version}.tar.gz"

  release '4.0.9', crystax: 3

  depends_on 'xz'
  depends_on 'libjpeg'

  build_copy 'COPYRIGHT'
  build_options use_cxx: true,
                copy_installed_dirs: ['bin', 'include', 'lib']

  def build_for_abi(abi, _toolchain, _release, _options)
    args = [ "--prefix=#{install_dir_for_abi(abi)}",
             "--host=#{host_for_abi(abi)}",
             "--disable-silent-rules",
             "--enable-shared",
             "--enable-static",
             "--disable-rpath",
             "--with-pic",
             "--with-jpeg-include-dir=#{target_dep_include_dir('libjpeg')}",
             "--with-jpeg-lib-dir=#{target_dep_lib_dir('libjpeg', abi)}",
             "--with-lzma-include-dir=#{target_dep_include_dir('xz')}",
             "--with-lzma-lib-dir=#{target_dep_lib_dir('xz', abi)}",
             "--disable-jbig",
             "--enable-cxx"
           ]

    configure *args
    make
    make 'install'

    clean_install_dir abi
  end
end
