class Curl < Utility

  desc 'Get a file from an HTTP, HTTPS or FTP server'
  homepage 'http://curl.haxx.se/'
  url 'https://curl.haxx.se/download/curl-${version}.tar.bz2'

  release version: '7.48.0', crystax_version: 1, sha256: { linux_x86_64:   '005158291e9b2b9b965a04913b6b03e1466de0a1402274f65fbc05a330d653e1',
                                                           darwin_x86_64:  '0',
                                                           windows_x86_64: '76fa24cb9b5320ec14c2c208e661e2ac5c3e5ea45ffd4b7f053cf2e09fc5bba9',
                                                           windows:        '4612850f2b3a8c254d6e771d75d500ecf1ccc661344472c82e3a970b2d3ad269'
                                                         }

  build_depends_on 'zlib'
  build_depends_on 'openssl'
  build_depends_on 'libssh2'

  def build_for_platform(platform, release, options, host_dep_dirs, _target_dep_dirs)
    install_dir = install_dir_for_platform(platform, release)
    zlib_dir    = host_dep_dirs[platform.name]['zlib']
    openssl_dir = host_dep_dirs[platform.name]['openssl']
    libssh2_dir = host_dep_dirs[platform.name]['libssh2']

    build_env['CPPFLAGS'] = "-DCURL_STATICLIB"
    build_env['LIBS']     = '-ldl'      if platform.target_os == 'linux'
    build_env['LIBS']     = '-lcrypt32' if platform.target_os == 'windows'

    args = ["--prefix=#{install_dir}",
            "--host=#{platform.configure_host}",
            "--disable-shared",
            "--disable-ldap",
            "--with-ssl=#{openssl_dir}",
            "--with-zlib=#{zlib_dir}",
            "--with-libssh2=#{libssh2_dir}"
           ]

    system "#{src_dir}/configure", *args
    system 'make', '-j', num_jobs
    system 'make', 'test' if options.check? platform
    system 'make', 'install'

    # remove unneeded files before packaging
    FileUtils.cd(install_dir) { FileUtils.rm_rf(['include', 'lib', 'share']) }
  end
end
