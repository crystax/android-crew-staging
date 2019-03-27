class Libffi < Package

  desc 'A portable foreign-function interface library'
  homepage 'https://github.com/libffi/libffi'
  url 'ftp://sourceware.org/pub/libffi/libffi-${version}.tar.gz'

  release '3.2.1', crystax: 5

  build_copy 'LICENSE'

  def build_for_abi(abi, _toolchain, release, _options)
    install_dir = install_dir_for_abi(abi)
    args =  [ "--disable-silent-rules",
              "--enable-shared",
              "--enable-static",
              "--with-sysroot",
              "--includedir=#{install_dir}/include"
            ]

    configure *args
    make
    make 'install'

    FileUtils.cd(install_dir) do
      if Dir.exist?('lib64')
        FileUtils.rm_rf 'lib'
        FileUtils.mv 'lib64', 'lib'
      end
    end

    clean_install_dir abi
  end

  def pc_edit_file(file, release, abi)
    super file, release, abi
    replace_lines_in_file(file) { |line| line.sub(/-L\${toolexeclibdir}/, '-L\${libdir}') }
    end
end
