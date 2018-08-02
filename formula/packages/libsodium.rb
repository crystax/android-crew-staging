class Libsodium < Package

  desc "NaCl networking and cryptography library"
  homepage "https://github.com/jedisct1/libsodium/"
  url "https://github.com/jedisct1/libsodium/releases/download/${version}/libsodium-${version}.tar.gz"

  release '1.0.16'

  build_copy 'LICENSE'

  def build_for_abi(abi, _toolchain, _release, _options)
    args =  [ "--prefix=#{install_dir_for_abi(abi)}",
              "--host=#{host_for_abi(abi)}",
              "--disable-silent-rules",
              "--with-pic"
            ]

    configure *args
    make
    make 'install'
    clean_install_dir abi
  end
end
