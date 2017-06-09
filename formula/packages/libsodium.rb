class Libsodium < Package

  desc "NaCl networking and cryptography library"
  homepage "https://github.com/jedisct1/libsodium/"
  url "https://github.com/jedisct1/libsodium/releases/download/1.0.10/libsodium-${version}.tar.gz"

  release version: '1.0.10', crystax_version: 1, sha256: '0'

  build_copy 'LICENSE'

  def build_for_abi(abi, _toolchain, _release, _host_dep_dirs, _target_dep_dirs, _options)
    install_dir = install_dir_for_abi(abi)
    args =  [ "--prefix=#{install_dir}",
              "--host=#{host_for_abi(abi)}",
              "--with-pic"
            ]

    system './configure', *args
    system 'make', '-j', num_jobs, 'V=1'
    system 'make', 'install'

    # remove unneeded files
    FileUtils.cd("#{install_dir}/lib") { FileUtils.rm_rf Dir['*.la'] + ['pkgconfig'] }
  end
end
