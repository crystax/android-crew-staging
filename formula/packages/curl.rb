class Curl < Package

  desc 'Get a file from an HTTP, HTTPS or FTP server'
  homepage 'http://curl.haxx.se/'
  url 'https://curl.haxx.se/download/curl-${version}.tar.bz2'

  release version: '7.58.0', crystax_version: 4

  depends_on 'openssl'
  depends_on 'libssh2'

  build_options copy_installed_dirs: ['bin', 'include', 'lib']

  build_copy 'COPYING'

  def build_for_abi(abi, _toolchain,  _release, _host_dep_dirs, target_dep_dirs, _options)
    install_dir = install_dir_for_abi(abi)
    openssl_dir = target_dep_dirs['openssl']
    libssh2_dir = target_dep_dirs['libssh2']


    args =  [ "--prefix=#{install_dir}",
              "--host=#{host_for_abi(abi)}",
              "--with-ssl=#{openssl_dir}",
              "--with-libssh2",
              "--disable-nls",
             " --disable-silent-rules"
            ]

    build_env['CFLAGS']  += " -I#{openssl_dir}/include -I#{libssh2_dir}/include"
    build_env['LDFLAGS'] += " -L#{openssl_dir}/libs/#{abi} -L#{libssh2_dir}/libs/#{abi}"

    system './configure', *args

    fix_makefile if ['mips', 'arm64-v8a', 'mips64'].include? abi

    system 'make', '-j', num_jobs
    system 'make', 'install'

    clean_install_dir abi, :lib
  end

  # for some reason libtool for some abis does not handle dependency libs
  def fix_makefile
    replace_lines_in_file('src/Makefile') do |line|
      if not line =~ /^LDFLAGS =[ \t]*/
        line
      else
        line.gsub('LDFLAGS =', 'LDFLAGS = -lssh2 -lssl -lcrypto -lz ')
      end
    end
  end
end
