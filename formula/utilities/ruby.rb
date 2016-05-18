class Ruby < Utility

  desc 'Powerful, clean, object-oriented scripting language'
  homepage 'https://www.ruby-lang.org/'
  url 'https://cache.ruby-lang.org/pub/ruby/${block}/ruby-${version}.tar.gz' do |v| v.split('.').slice(0, 2).join('.') end

  role :core

  release version: '2.2.2', crystax_version: 1, sha256: { linux_x86_64:   '0',
                                                          darwin_x86_64:  '0',
                                                          windows_x86_64: '0',
                                                          windows:        '0'
                                                        }

  build_depends_on 'zlib'
  build_depends_on 'openssl'
  build_depends_on 'libssh2'
  build_depends_on 'libgit2'

  def build_for_platform(platform, release, options, dep_dirs)
    install_dir = install_dir_for_platform(platform, release)
    zlib_dir    = dep_dirs[platform.name]['zlib']
    openssl_dir = dep_dirs[platform.name]['openssl']
    libssh2_dir = dep_dirs[platform.name]['libssh2']
    libgit2_dir = dep_dirs[platform.name]['libgit2']

    cflags  = "-I#{zlib_dir}/include -I#{openssl_dir}/include #{platform.cflags}"
    ldflags = "-L#{libssh2_dir}/lib -L#{libgit2_dir}/lib -L#{zlib_dir}/lib"
    if platform.target_os != 'windows'
      libs = '-lz -lgit2 -lssh2 -lz'
    else
      libs = "#{zlib_dir}/lib/libz.a #{libgit2_dir}/lib/libgit2.a #{libssh2_dir}/lib/libssh2.a #{zlib_dir}/lib/libz.a"
    end

    build_env['CC']            = platform.cc
    build_env['CFLAGS']        = cflags
    build_env['LDFLAGS']       = ldflags
    build_env['LIBS']          = libs
    build_env['SSL_CERT_FILE'] = host_ssl_cert_file

    args = ["--prefix=#{install_dir}",
            "--host=#{platform.configure_host}",
            "--disable-install-doc",
            "--enable-load-relative",
            "--with-openssl-dir=#{openssl_dir}",
            "--with-static-linked-ext",
            "--without-gmp",
            "--without-tk",
            "--without-gdbm",
            "--enable-bundled-libyaml"
           ]

    system "#{src_dir}/configure", *args
    #fix_winres_params if options.target_platform == 'windows'
    system 'make', '-j', num_jobs, 'V=1'
    system 'make', 'test' if options.check? platform
    system 'make', 'install'

    install_gems install_dir, 'rspec', 'minitest'
  end

  def install_gems(install_dir, *gems)
    build_env.clear
    build_env['GEM_HOME'] = "#{install_dir}/lib/ruby/gems/2.2.0"
    build_env['GEM_PATH'] = "#{install_dir}/lib/ruby/gems/2.2.0"
    build_env['SSL_CERT_FILE'] = host_ssl_cert_file

    args = ['-V',
            '--no-document',
            '--backtrace',
            "--bindir #{install_dir}/bin"
           ]

    system 'gem', 'install', *args, *gems
  end

  def host_ssl_cert_file
    case Global::OS
    when 'darwin'
      '/usr/local/etc/openssl/osx_cert.pem'
    when 'linux'
      '/etc/ssl/certs/ca-certificates.crt'
    else
      raise "unsupported host OS for ssl sert file: #{Global::OS}"
    end
  end
end
