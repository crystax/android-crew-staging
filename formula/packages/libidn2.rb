class Libidn2 < Package

  desc "Libidn2 is an implementation of the IDNA2008 + TR46 specifications"
  homepage "https://www.gnu.org/software/libidn/#libidn2"
  url "https://ftp.gnu.org/gnu/libidn/libidn2-${version}.tar.gz"

  release version: '2.0.4', crystax_version: 2

  depends_on 'libunistring'

  build_copy 'COPYING', 'COPYING.LESSERv3', 'COPYING.unicode', 'COPYINGv2'
  build_options copy_installed_dirs: ['bin', 'include', 'lib']

  def build_for_abi(abi, _toolchain, _release, _host_dep_dirs, target_dep_dirs, _options)
    install_dir = install_dir_for_abi(abi)
    libunistring_dir = target_dep_dirs['libunistring']

    build_env['CFLAGS']  += " -I#{libunistring_dir}/include"
    build_env['LDFLAGS'] += " -L#{libunistring_dir}/libs/#{abi}"

    args =  [ "--prefix=#{install_dir}",
              "--host=#{host_for_abi(abi)}",
              "--disable-silent-rules",
              "--enable-shared",
              "--enable-static",
              "--disable-doc",
              "--disable-nls",
              "--with-pic",
              "--with-sysroot"
            ]

    system './configure', *args
    system 'make', '-j', num_jobs, 'V=1'
    system 'make', 'install'

    clean_install_dir abi, :lib
  end
end
