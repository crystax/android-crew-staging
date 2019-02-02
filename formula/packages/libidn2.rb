class Libidn2 < Package

  desc "Libidn2 is an implementation of the IDNA2008 + TR46 specifications"
  homepage "https://www.gnu.org/software/libidn/#libidn2"
  url "https://ftp.gnu.org/gnu/libidn/libidn2-${version}.tar.gz"

  release '2.1.0'

  depends_on 'libunistring'

  build_copy 'COPYING', 'COPYING.LESSERv3', 'COPYING.unicode', 'COPYINGv2'
  build_options add_deps_to_cflags: true,
                add_deps_to_ldflags: true,
                copy_installed_dirs: ['bin', 'include', 'lib']

  def build_for_abi(abi, _toolchain, release, _options)
    args =  [ "--disable-silent-rules",
              "--enable-shared",
              "--enable-static",
              "--disable-doc",
              "--disable-nls",
              "--with-pic",
              "--with-sysroot"
            ]

    configure *args
    make
    make 'install'

    clean_install_dir abi
  end

  def pc_edit_file(file, release, abi)
    super file, release, abi

    replace_lines_in_file(file) do |line|
      if line =~ /^Libs.private: /
        'Libs.private: -lunistring'
      else
        line
      end
    end
  end
end
