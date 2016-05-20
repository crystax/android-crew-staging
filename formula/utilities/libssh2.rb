class Libssh2 < Utility

  desc "A Massively Spiffy Yet Delicately Unobtrusive Compression Library"
  homepage 'http://www.libssh2.org/'
  url 'http://www.libssh2.org/download/libssh2-${version}.tar.gz'

  release version: '1.7.0', crystax_version: 1, sha256: { linux_x86_64:   '0',
                                                          darwin_x86_64:  '0',
                                                          windows_x86_64: '0',
                                                          windows:        '0'
                                                        }

  build_depends_on 'zlib'
  build_depends_on 'openssl'

  def build_for_platform(platform, release, options, dep_dirs)
    install_dir = install_dir_for_platform(platform, release)
    zlib_dir    = dep_dirs[platform.name]['zlib']
    openssl_dir = dep_dirs[platform.name]['openssl']

    build_env['CC']      = platform.cc
    build_env['CFLAGS']  = "-I#{openssl_dir}/include -I#{zlib_dir}/include #{platform.cflags}"
    build_env['LDFLAGS'] = "-L#{openssl_dir}/lib -L#{zlib_dir}/lib -lz"
    build_env['LIBS']    = "-lcrypt32 -lgdi32" if platform.target_os == 'windows'
    build_env['LIBS']    = "-ldl"              if platform.target_os == 'linux'

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
  end
end
