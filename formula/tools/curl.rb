class Curl < Utility

  desc 'Get a file from an HTTP, HTTPS or FTP server'
  homepage 'http://curl.haxx.se/'
  url 'https://curl.haxx.se/download/curl-${version}.tar.bz2'

  release version: '7.48.0', crystax_version: 1, sha256: { linux_x86_64:   '3e228c41da62a87b5a8a3bc9220d833c9fd0c905b24432f895b12b7e4d084ae1',
                                                           darwin_x86_64:  '5aa198ab72b613bd7055243ec6be64d2c9344ebdd670849c0ebc8dcfc99f5a76',
                                                           windows_x86_64: 'fc040fe41a67f51c36135e0be275708591d0e1a99d2eb01746360c11f3fffa83',
                                                           windows:        'ec2c055540dce82220fbf73cb864339ab8f2e7c15081e4df1a57387a39476830'
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
