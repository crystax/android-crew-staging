class Xz < Package

  desc "General-purpose data compression with high compression ratio"
  homepage "http://tukaani.org/xz/"
  url "http://tukaani.org/xz/xz-${version}.tar.xz"

  release '5.2.4'

  build_copy 'COPYING'
  build_options copy_installed_dirs: ['bin', 'include', 'lib']

  def build_for_abi(abi, _toolchain,  _release, _options)
    args =  [ "--prefix=#{install_dir_for_abi(abi)}",
              "--host=#{host_for_abi(abi)}",
              "--disable-silent-rules",
              "--disable-nls",
              "--disable-doc",
              "--disable-lzma-links",
              "--enable-shared",
              "--enable-static",
              "--with-pic",
              "--with-sysroot"
            ]

    configure *args
    make
    make 'install'

    clean_install_dir abi
  end
end
