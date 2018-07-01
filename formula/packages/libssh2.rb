class Libssh2 < Package

  desc "libssh2 is a client-side C library implementing the SSH2 protocol"
  homepage 'http://www.libssh2.org/'
  url 'http://www.libssh2.org/download/libssh2-${version}.tar.gz'

  release '1.8.0', crystax: 4

  depends_on 'openssl'

  #build_copy 'README'

  def build_for_abi(abi, _toolchain, _release, _host_dep_dirs, target_dep_dirs, _options)
    install_dir = install_dir_for_abi(abi)
    openssl_dir = target_dep_dirs['openssl']

    args =  [ "--prefix=#{install_dir}",
              "--host=#{host_for_abi(abi)}",
              "--disable-silent-rules",
              "--disable-examples-build",
              "--enable-shared",
              "--enable-static",
              "--with-openssl",
              "--with-libz",
              "--with-libssl-prefix=#{openssl_dir}"
            ]

    build_env['CFLAGS']  += " -I#{openssl_dir}/include"
    build_env['LDFLAGS'] += " -L#{openssl_dir}/libs/#{abi}"

    system './configure', *args

    # for some reason libtool for some abis does not handle dependency libs
    fix_tests_makefile if ['mips', 'arm64-v8a', 'mips64'].include? abi

    system 'make', '-j', num_jobs, 'V=1'
    system 'make', 'install'

    # remove unneeded files
    FileUtils.cd(install_dir) do
      FileUtils.rm_rf ['share', 'lib/pkgconfig']
      FileUtils.rm Dir["lib/*.la"]
    end
  end

  def fix_tests_makefile
    makefile = 'tests/Makefile'
    lines = []
    replaced = false
    File.foreach(makefile) do |l|
      if not l =~ /^LIBS =[ \t]*/
        lines << l
      else
        lines << l.gsub('LIBS =', 'LIBS = -lssl -lcrypto -lz ')
        replaced = true
      end
    end

    raise "not found 'LIBS =' line in #{makefile}" unless replaced

    File.open(makefile, 'w') { |f| f.puts lines }
  end
end
