class Libtiff < Package

  desc "TIFF library"
  homepage "http://www.libtiff.org"
  url "http://download.osgeo.org/libtiff/tiff-${version}.tar.gz"

  release version: '4.0.9', crystax_version: 1

  depends_on 'xz'
  depends_on 'libjpeg'

  build_copy 'COPYRIGHT'
  build_options use_cxx: true,
                copy_installed_dirs: ['bin', 'include', 'lib']

  def build_for_abi(abi, _toolchain, _release, _host_dep_dirs, target_dep_dirs, _options)
    install_dir = install_dir_for_abi(abi)
    libjpeg_dir = target_dep_dirs['libjpeg']
    xz_dir = target_dep_dirs['xz']

    args = [ "--prefix=#{install_dir}",
             "--host=#{host_for_abi(abi)}",
             "--disable-silent-rules",
             "--enable-shared",
             "--enable-static",
             "--disable-rpath",
             "--with-pic",
             "--with-jpeg-include-dir=#{libjpeg_dir}/include",
             "--with-jpeg-lib-dir=#{libjpeg_dir}/libs/#{abi}",
             "--with-lzma-include-dir=#{xz_dir}/include",
             "--with-lzma-lib-dir=#{xz_dir}/libs/#{abi}",
             "--disable-jbig",
             "--enable-cxx"
           ]

    system './configure', *args
    system 'make', '-j', num_jobs
    system 'make', 'install'

    clean_install_dir abi, :lib
  end
end
