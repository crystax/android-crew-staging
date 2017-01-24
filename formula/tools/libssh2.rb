class Libssh2 < BuildDependency

  desc "A Massively Spiffy Yet Delicately Unobtrusive Compression Library"
  homepage 'http://www.libssh2.org/'
  url 'http://www.libssh2.org/download/libssh2-${version}.tar.gz'

  release version: '1.7.0', crystax_version: 1, sha256: { linux_x86_64:   'c7cc5da9231f3b7fac0488c01852a383234924acb81c3d6e6007f03c452467fe',
                                                          darwin_x86_64:  'ad2b41bf197a0ef4b260f1c2140ef2355f818f6372cbeb5aa1fd006d85606aa4',
                                                          windows_x86_64: '8cf8d142c292a2db2252de22e322c21db91f064382dcf64c5d32c8d2b3b1ab8a',
                                                          windows:        'd3fbd0bfe8678a0e12e5fcdd5530de8580c15b3533929004324df94d6a5df031'
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
