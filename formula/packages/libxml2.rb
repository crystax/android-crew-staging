class Libxml2 < Package

  desc "A low-level cryptographic library"
  homepage "http://www.xmlsoft.org"
  url "ftp://xmlsoft.org/libxml2/libxml2-${version}.tar.gz"

  release '2.9.8', crystax: 2

  depends_on 'xz'

  build_copy 'COPYING'
  build_options support_pkgconfig: true

  def build_for_abi(abi, _toolchain, _release, _options)
    install_dir = install_dir_for_abi(abi)

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

    configure *args
    make
    make 'install'

    clean_install_dir abi
    FileUtils.cd("#{install_dir}/lib") { FileUtils.rm 'xml2Conf.sh' }
  end

  def pc_edit_file(file, release, abi)
    super file, release, abi

    replace_lines_in_file(file) do |line|
      if line =~ /^Libs.private:/
        'Libs.private: -lz -llzma -lm'
      else
        line
      end
    end
  end
end
