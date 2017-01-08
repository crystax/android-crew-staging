class Libssh2 < BuildDependency

  desc "A Massively Spiffy Yet Delicately Unobtrusive Compression Library"
  homepage 'http://www.libssh2.org/'
  url 'http://www.libssh2.org/download/libssh2-${version}.tar.gz'

  release version: '1.7.0', crystax_version: 1, sha256: { linux_x86_64:   '14c27f40c15288920dc544ef7cf96c740883ecf56906a61bab05118756fcc2fe',
                                                          darwin_x86_64:  'e0290a11ee2af9d7eb65007b1bda661a4378cbd323890a58bc3f71ee240dbc1e',
                                                          windows_x86_64: '25b0fac82061fa5ae50189e1b18c26ce68301f56df1080c8a5ac42f1bb456344',
                                                          windows:        '9e96f85fe8eded8796aa114d0c3b45ffb4294ec2587acd6a5d3396ece07610fa'
                                                        }

  depends_on 'zlib'
   # todo: depends on openssl 1.0.*
  depends_on 'openssl'

  def build_for_platform(platform, release, options, host_dep_dirs, _target_dep_dirs)
    install_dir = install_dir_for_platform(platform, release)
    zlib_dir    = host_dep_dirs[platform.name]['zlib']
    openssl_dir = host_dep_dirs[platform.name]['openssl']

    build_env['CFLAGS']  += " -I#{openssl_dir}/include -I#{zlib_dir}/include #{platform.cflags}"
    build_env['LDFLAGS']  = "-L#{openssl_dir}/lib -L#{zlib_dir}/lib -lz"
    build_env['LIBS']     = "-lcrypt32 -lgdi32" if platform.target_os == 'windows'
    build_env['LIBS']     = "-ldl"              if platform.target_os == 'linux'

    args = ["--prefix=#{install_dir}",
            "--host=#{platform.configure_host}",
            "--disable-shared",
            "--disable-examples-build",
            "--with-libssl-prefix=#{openssl_dir}",
            "--with-libz=#{zlib_dir}"
           ]

    system "#{src_dir}/configure",  *args
    system 'make', '-j', num_jobs, 'V=1'
    system 'make', 'check' if options.check? platform
    system 'make', 'install'

    # remove unneeded files
    FileUtils.rm_rf File.join(install_dir, 'lib', 'pkgconfig')
    FileUtils.rm_rf File.join(install_dir, 'share')
  end
end
