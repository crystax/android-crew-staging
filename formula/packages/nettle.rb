class Nettle < Package

  desc "A low-level cryptographic library"
  homepage "https://www.lysator.liu.se/~nisse/nettle/"
  url "https://ftp.gnu.org/gnu/nettle/nettle-${version}.tar.gz"

  release '3.4.1', crystax: 3

  depends_on 'openssl'
  depends_on 'gmp'

  build_libs 'libhogweed', 'libnettle'
  build_copy 'COPYING.LESSERv3', 'COPYINGv2', 'COPYINGv3'
  build_options use_cxx: true,
                add_deps_to_cflags: true,
                add_deps_to_ldflags: true


  def build_for_abi(abi, _toolchain, _release, _options)
    install_dir = install_dir_for_abi(abi)

    args =  [ "--enable-shared",
              "--enable-static",
              "--disable-openssl",
              "--disable-documentation"
            ]

    configure *args
    make
    make 'install'

    clean_install_dir abi
    FileUtils.cd("#{install_dir}/lib") do
      FileUtils.mv 'libhogweed.so.4.5', 'libhogweed.so'
      FileUtils.mv 'libnettle.so.6.5',  'libnettle.so'
    end
  end

  def sonames_translation_table(_release)
    { 'libhogweed.so.4' => 'libhogweed',
      'libnettle.so.6'  => 'libnettle'
    }
  end
end
