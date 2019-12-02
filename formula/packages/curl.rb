class Curl < Package

  desc 'Get a file from an HTTP, HTTPS or FTP server'
  homepage 'https://curl.haxx.se/'
  url 'https://curl.haxx.se/download/curl-${version}.tar.bz2'

  release '7.65.0', crystax: 2

  depends_on 'openssl'
  depends_on 'libssh2'

  build_copy 'COPYING'
  build_options support_pkgconfig: false,
                copy_installed_dirs: ['bin', 'include', 'lib']

  def build_for_abi(abi, _toolchain,  _release, _options)
    args =  [ "--with-ssl",
              "--with-libssh2",
              "--disable-nls",
             " --disable-silent-rules"
            ]

    # for some reason libtool for some abis does not handle dependency libs
    build_env['LDFLAGS'] += ' -lssh2 -lssl -lcrypto -lz' if ['arm64-v8a'].include? abi

    configure *args
    make '-j', num_jobs
    make 'install'

    clean_install_dir abi
  end
end
