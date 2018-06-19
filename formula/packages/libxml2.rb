class Libxml2 < Package

  desc "A low-level cryptographic library"
  homepage "http://www.xmlsoft.org"
  url "ftp://xmlsoft.org/libxml2/libxml2-${version}.tar.gz"

  release version: '2.9.8', crystax_version: 1

  depends_on 'xz'

  # build_options use_cxx: true
  # build_copy 'COPYING.LESSERv3', 'COPYINGv2', 'COPYINGv3'
  # build_libs 'libhogweed', 'libnettle'

  def build_for_abi(abi, _toolchain, _release, _host_dep_dirs, target_dep_dirs, _options)
    install_dir = install_dir_for_abi(abi)
    xz_dir = target_dep_dirs['xz']

    args =  [ "--prefix=#{install_dir}",
              "--host=#{host_for_abi(abi)}",
              "--disable-silent-rules",
              "--enable-shared",
              "--enable-static",
              "--with-pic",
              "--with-sysroot",
              "--without-icu",
              "--without-python"
            ]

    build_env['LZMA_CFLAGS'] = target_dep_include_dir(xz_dir)
    build_env['LZMA_LIBS']   = target_dep_lib_dir(xz_dir, abi) + ' -llzma'

    build_env['CFLAGS']  += ' ' + build_env['LZMA_CFLAGS']
    build_env['LDFLAGS'] += ' ' + build_env['LZMA_LIBS']


    system './configure', *args
    system 'make', '-j', num_jobs
    system 'make', 'install'

    clean_install_dir abi, :lib
    FileUtils.cd("#{install_dir}/lib") { FileUtils.rm 'xml2Conf.sh' }
  end
end
