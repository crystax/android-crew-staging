class Nettle < Package

  desc "A low-level cryptographic library"
  homepage "https://www.lysator.liu.se/~nisse/nettle/"
  url "https://ftp.gnu.org/gnu/nettle/nettle-${version}.tar.gz"

  release '3.4'

  depends_on 'openssl'
  depends_on 'gmp'

  build_options use_cxx: true
  build_copy 'COPYING.LESSERv3', 'COPYINGv2', 'COPYINGv3'
  build_libs 'libhogweed', 'libnettle'

  def build_for_abi(abi, _toolchain, _release, _host_dep_dirs, target_dep_dirs, _options)
    install_dir = install_dir_for_abi(abi)
    openssl_dir = target_dep_dirs['openssl']
    gmp_dir     = target_dep_dirs['gmp']

    args =  [ "--prefix=#{install_dir}",
              "--host=#{host_for_abi(abi)}",
              "--enable-shared",
              "--enable-static",
              "--disable-openssl",
              "--disable-documentation",
              "--with-include-path=#{openssl_dir}/include:#{gmp_dir}/include",
              "--with-lib-path=#{openssl_dir}/libs/#{abi}:#{gmp_dir}/libs/#{abi}"
            ]

    system './configure', *args
    system 'make', '-j', num_jobs
    system 'make', 'install'

    # cleanup lib directory
    FileUtils.cd("#{install_dir}/lib") do
      FileUtils.rm_rf 'pkgconfig'
      FileUtils.rm ['libhogweed.so', 'libnettle.so', 'libhogweed.so.4', 'libnettle.so.6']
      FileUtils.mv 'libhogweed.so.4.4', 'libhogweed.so'
      FileUtils.mv 'libnettle.so.6.4',  'libnettle.so'
    end
  end

  def sonames_translation_table(_release)
    { 'libhogweed.so.4' => 'libhogweed',
      'libnettle.so.6'  => 'libnettle'
    }
  end
end
