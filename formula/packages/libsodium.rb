class Libsodium < Package

  desc "NaCl networking and cryptography library"
  homepage "https://github.com/jedisct1/libsodium/"
  url "https://github.com/jedisct1/libsodium/releases/download/${version}/libsodium-${version}.tar.gz"

  release '1.0.17'

  build_copy 'LICENSE'

  def build_for_abi(abi, _toolchain, _release, _options)
    args =  [ "--disable-silent-rules", "--with-pic" ]
    configure *args
    make
    make 'install'
    clean_install_dir abi
  end
end
