class Libssh2 < Package

  desc "libssh2 is a client-side C library implementing the SSH2 protocol"
  homepage 'http://www.libssh2.org/'
  url 'http://www.libssh2.org/download/libssh2-${version}.tar.gz'

  release '1.8.0', crystax: 5

  depends_on 'openssl'

  build_copy 'COPYING'
  build_options add_deps_to_cflags: true,
                add_deps_to_ldflags: true

  def build_for_abi(abi, _toolchain, _release, _options)
    args =  [ "--prefix=#{install_dir_for_abi(abi)}",
              "--host=#{host_for_abi(abi)}",
              "--disable-silent-rules",
              "--disable-examples-build",
              "--enable-shared",
              "--enable-static",
              "--with-openssl",
              "--with-libz"
            ]

    configure *args

    # for some reason libtool for some abis does not handle dependency libs
    fix_tests_makefile if ['mips', 'arm64-v8a', 'mips64'].include? abi

    make
    make 'install'

    clean_install_dir abi
  end

  def fix_tests_makefile
    replace_lines_in_file('tests/Makefile') do |line|
      if line =~ /^LIBS =[ \t]*/
        line.gsub('LIBS =', 'LIBS = -lssl -lcrypto -lz ')
      else
        line
      end
    end
  end
end
