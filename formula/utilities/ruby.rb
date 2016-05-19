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

  def download_rugged(rugged_ver, dir, log_prefix)
  end

  def copy_rugged(src, dst)
  end

  def patch_rugged(rugged_dst)
  end

  def prepare_source_code(release, dir, src_name, log_prefix)
    super(release, dir, src_name, log_prefix)

    # todo: get installed libgit2 version and make rugged version out of it
    rugged_ver = '0.24.0'

    # download and unpack rugged sources
    rugged_url = "https://github.com/libgit2/rugged/archive/v#{rugged_ver}.tar.gz"
    rugged_archive = File.join(Global::CACHE_DIR, File.basename(URI.parse(rugged_url).path))
    if File.exists? rugged_archive
      puts "#{log_prefix} using cached file #{rugged_archive}"
    else
      puts "#{log_prefix} downloading #{rugged_url}"
      Utils.download(rugged_url, rugged_archive)
    end
    puts "#{log_prefix} unpacking #{File.basename(rugged_archive)} into #{dir}"
    Utils.unpack(rugged_archive, dir)

    # copy rugged sources into ruby source code tree
    rugged_src = File.join(dir, "rugged-#{rugged_ver}")
    rugged_dst = "#{src_dir}/ext/rugged"
    FileUtils.mkdir_p "#{rugged_dst}/lib"
    FileUtils.cp_r Dir["#{rugged_src}/ext/rugged/*"], "#{rugged_dst}/"
    FileUtils.cp_r Dir["#{rugged_src}/lib/*"], "#{rugged_dst}/lib/"

    # patch rugged sources
    patches = []
    mask = File.join(Global::PATCHES_DIR, TYPE_DIR[type], 'rugged', '*.patch')
    Dir[mask].each { |p| patches << Patch::File.new(p) }
    puts "#{log_prefix} patching in dir #{rugged_dst}"
    patches.each do |p|
      puts "#{log_prefix}   applying #{File.basename(p.path)}"
      p.apply rugged_dst
    end
  end

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

    build_env['CC']              = platform.cc
    build_env['CFLAGS']          = cflags
    build_env['LDFLAGS']         = ldflags
    build_env['LIBS']            = libs
    build_env['SSL_CERT_FILE']   = host_ssl_cert_file
    build_env['RUGGED_CFLAGS']   = "#{cflags} -DRUBY_UNTYPED_DATA_WARNING=0 -I#{openssl_dir}/include -I#{libssh2_dir}/include -I#{libgit2_dir}/include"
    build_env['RUGGED_MAKEFILE'] = "#{src_dir}/ext/rugged/Makefile"

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
