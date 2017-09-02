class Libssh2 < BuildDependency

  desc "A Massively Spiffy Yet Delicately Unobtrusive Compression Library"
  homepage 'http://www.libssh2.org/'
  url 'http://www.libssh2.org/download/libssh2-${version}.tar.gz'

  release version: '1.8.0', crystax_version: 2

  depends_on 'zlib'
  # todo: depends on openssl 1.0.*
  depends_on 'openssl'

  def build_for_platform(platform, release, options, host_dep_dirs, _target_dep_dirs)
    install_dir = install_dir_for_platform(platform.name, release)
    zlib_dir    = host_dep_dirs[platform.name]['zlib']
    openssl_dir = host_dep_dirs[platform.name]['openssl']

    build_env['CFLAGS']  += " -I#{openssl_dir}/include -I#{zlib_dir}/include #{platform.cflags}"
    build_env['LDFLAGS']  = "-L#{openssl_dir}/lib -L#{zlib_dir}/lib -lz"
    build_env['LIBS']     = "-lcrypt32 -lgdi32" if platform.target_os == 'windows'
    build_env['LIBS']     = "-ldl"              if platform.target_os == 'linux'

    args = platform.configure_args +
           ["--prefix=#{install_dir}",
            "--disable-examples-build",
            "--with-libssl-prefix=#{openssl_dir}",
            "--with-libz=#{zlib_dir}"
           ]

    system "#{src_dir}/configure",  *args
    system 'make', '-j', num_jobs, 'V=1'
    system 'make', 'check' if options.check? platform
    system 'make', 'install'

    # remove unneeded files
    FileUtils.rm_rf "#{install_dir}/lib/pkgconfig"
    FileUtils.rm_rf "#{install_dir}/share"
    FileUtils.rm_rf Dir["#{install_dir}/lib/*.la"]
  end
end
