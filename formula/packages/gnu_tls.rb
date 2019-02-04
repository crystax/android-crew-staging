class GnuTls < Package

  name 'gnu-tls'
  desc "GnuTLS is a secure communications library implementing the SSL, TLS and DTLS protocols and technologies around them"
  homepage "https://www.gnutls.org"
  url "https://www.gnupg.org/ftp/gcrypt/gnutls/v${block}/gnutls-${version}.tar.xz" do |r| r.version.split('.').first(2).join('.') end

  release '3.6.6'

  depends_on 'gmp'
  depends_on 'libffi'
  depends_on 'libunistring'
  depends_on 'nettle'
  depends_on 'libidn2'
  depends_on 'p11-kit'

  build_copy 'LICENSE'
  build_libs 'libgnutls', 'libgnutlsxx'
  build_options use_cxx: true,
                copy_installed_dirs: ['bin', 'include', 'lib']

  def build_for_abi(abi, _toolchain, release, _options)
    args =  [ "--disable-silent-rules",
              "--disable-doc",
              "--enable-shared",
              "--enable-static",
              "--disable-nls",
              "--with-included-libtasn1",
              "--with-pic",
              "--with-sysroot"
            ]

    build_env['CFLAGS']  += " -I#{target_dep_include_dir('libidn2')}"
    build_env['LDFLAGS'] += " -L#{target_dep_lib_dir('libunistring', abi)} -L#{target_dep_lib_dir('libidn2', abi)} -lunistring -lidn2"

    if ['mips', 'arm64-v8a', 'mips64'].include? abi
      build_env['LDFLAGS'] += " -L#{target_dep_lib_dir('gmp', abi)} -L#{target_dep_lib_dir('nettle', abi)} -lhogweed -lnettle -lgmp"
    end

    configure *args
    fix_makefile abi if ['mips', 'arm64-v8a', 'mips64'].include? abi
    make
    make 'install'

    clean_install_dir abi
  end

  def pc_edit_file(file, release, abi)
    super file, release, abi

    replace_lines_in_file(file) do |line|
      if line =~ /^Libs.private: /
        'Libs.private: -lunistring -lgmp -lz'
      else
        line
      end
    end
  end

  # for some reason libtool for some abis does not handle dependency libs
  def fix_makefile(abi)
    replace_lines_in_file('src/Makefile') do |line|
      case line
      when /^LIBS =[ \t]*/
        line.gsub('LIBS =', 'LIBS = -lp11-kit -lidn2 -lunistring -lnettle -lhogweed -lffi -lgmp -lz ')
      when /^LDFLAGS =[ \t]*/
        line += " -L#{target_dep_lib_dir('libffi', abi)}" if abi == 'mips'
        line += " -L#{target_dep_lib_dir('p11-kit', abi)} -L#{target_dep_lib_dir('nettle', abi)}"
      else
        line
      end
    end
  end
end
