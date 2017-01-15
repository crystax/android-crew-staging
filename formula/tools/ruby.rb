class Ruby < Utility

  desc 'Powerful, clean, object-oriented scripting language'
  homepage 'https://www.ruby-lang.org/'
  url 'https://cache.ruby-lang.org/pub/ruby/${block}/ruby-${version}.tar.gz' do |r| r.version.split('.').slice(0, 2).join('.') end

  release version: '2.2.2', crystax_version: 1, sha256: { linux_x86_64:   'eff7d941e360f11f0b00b52c76ae80f7c3b54b6de5115ba195f09aa724e37450',
                                                          darwin_x86_64:  'ea636a6c8c64548461e12c57e634245491f5256ded8c2d04bfcc92727066ff1a',
                                                          windows_x86_64: '9787fae15f71dc6dfd59098b084038d837575d91aadc8fe598e5a734e1bc9556',
                                                          windows:        '1bca2d7b33564f1833467da1df4e1e4aeff99cb90a6540dea4c7ed808031e65d'
                                                        }

  build_depends_on 'zlib'
  build_depends_on 'openssl'
  build_depends_on 'libssh2'
  build_depends_on 'libgit2'

  executables 'ruby'

  def wrapper_script_lines(_exe, platform_name)
    platform_name.start_with?('windows') ? ['set GEM_HOME=', 'set GEM_PATH='] : ['unset GEM_HOME', 'unset GEM_PATH']
  end

  def prepare_source_code(release, dir, src_name, log_prefix)
    super(release, dir, src_name, log_prefix)

    # todo: get installed libgit2 version and make rugged version out of it
    rugged_ver = '0.24.0'

    # download and unpack rugged sources
    rugged_url = "https://github.com/libgit2/rugged/archive/v#{rugged_ver}.tar.gz"
    rugged_archive = src_cache_file(Release.new(rugged_ver), rugged_url)
    if File.exists? rugged_archive
      puts "#{log_prefix} using cached file #{rugged_archive}"
    else
      puts "#{log_prefix} downloading #{rugged_url}"
      Utils.download(rugged_url, rugged_archive)
    end
    puts "#{log_prefix} unpacking #{File.basename(rugged_archive)} into #{dir}"
    Utils.unpack(rugged_archive, dir)

    # patch rugged sources
    patches = []
    rugged_src = File.join(dir, "rugged-#{rugged_ver}")
    mask = File.join(Global::PATCHES_DIR, Global::NS_DIR[namespace], 'rugged', rugged_ver, '*.patch')
    Dir[mask].each { |f| patches << Patch::File.new(f) }
    puts "#{log_prefix} patching in dir #{rugged_src}"
    patches.each do |p|
      puts "#{log_prefix}   applying #{File.basename(p.path)}"
      p.apply rugged_src
    end

    # copy rugged sources into ruby source code tree
    rugged_dst = "#{src_dir}/ext/rugged"
    FileUtils.mkdir_p "#{rugged_dst}/lib"
    FileUtils.cp_r Dir["#{rugged_src}/ext/rugged/*"], "#{rugged_dst}/"
    FileUtils.cp_r Dir["#{rugged_src}/lib/*"], "#{rugged_dst}/lib/"
  end

  def build_for_platform(platform, release, options, host_dep_dirs, _target_dep_dirs)
    install_dir = install_dir_for_platform(platform, release)
    zlib_dir    = host_dep_dirs[platform.name]['zlib']
    openssl_dir = host_dep_dirs[platform.name]['openssl']
    libssh2_dir = host_dep_dirs[platform.name]['libssh2']
    libgit2_dir = host_dep_dirs[platform.name]['libgit2']

    cflags  = "-I#{zlib_dir}/include -I#{openssl_dir}/include #{platform.cflags}"
    ldflags = "-w -L#{libssh2_dir}/lib -L#{libgit2_dir}/lib -L#{openssl_dir}/lib -L#{zlib_dir}/lib"
    if platform.target_os != 'windows'
      libs = '-lz -lgit2 -lssh2 -lssl -lcrypto -lz'
    else
      libs = ["#{zlib_dir}/lib/libz.a",
              "#{libgit2_dir}/lib/libgit2.a",
              "#{libssh2_dir}/lib/libssh2.a",
              "#{openssl_dir}/lib/libssl.a",
              "#{openssl_dir}/lib/libcrypto.a",
              "#{zlib_dir}/lib/libz.a",
              "-lws2_32",
              "-lcrypt32",
              "-lgdi32"
             ].join(' ')
    end

    build_env['CFLAGS']          += ' ' + cflags
    build_env['LDFLAGS']         = ldflags
    build_env['LIBS']            = libs
    build_env['SSL_CERT_FILE']   = host_ssl_cert_file
    build_env['RUGGED_CFLAGS']   = "#{cflags} -DRUBY_UNTYPED_DATA_WARNING=0 -I#{openssl_dir}/include -I#{libssh2_dir}/include -I#{libgit2_dir}/include"
    build_env['RUGGED_MAKEFILE'] = "#{build_dir_for_platform(platform)}/ext/rugged/Makefile"
    build_env['DESTDIR']         = install_dir
    build_env['PATH']            = "#{File.dirname(platform.cc)}:#{ENV['PATH']}" if platform.target_os == 'windows'
    build_env['V']               = '1'

    args = ["--prefix=/",
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
    fix_winres_params if platform.target_os == 'windows' and platform.target_cpu == 'x86'
    fix_win_makefile  if platform.target_os == 'windows'
    system 'make', '-j', num_jobs
    system 'make', 'test' if options.check? platform
    system 'make', 'install'

    # remove unneeded files
    FileUtils.rm_rf File.join(install_dir, 'lib', 'pkgconfig')
    FileUtils.rm_rf File.join(install_dir, 'share')

    gem = gem_path(release, platform, install_dir)
    rspec_opts = (release.version == '2.2.2') ? { version: '3.4' } : {}
    install_gem gem, install_dir, 'rspec', rspec_opts
  end

  def install_gem(gem, install_dir, name, options = {})
    build_env.clear
    build_env['GEM_HOME'] = "#{install_dir}/lib/ruby/gems/2.2.0"
    build_env['GEM_PATH'] = "#{install_dir}/lib/ruby/gems/2.2.0"
    build_env['SSL_CERT_FILE'] = host_ssl_cert_file

    args = ['-V',
            '--no-document',
            '--backtrace',
            "--bindir #{install_dir}/bin"
           ]

    opts = ['-v', options[:version]] if options[:version]

    system gem, 'install', *args, name, *opts
  end

  def host_ssl_cert_file
    "#{Global::BASE_DIR}/etc/ca-certificates.crt"
    # case Global::OS
    # when 'darwin'
    #   '/usr/local/etc/openssl/osx_cert.pem'
    # when 'linux'
    #   '/etc/ssl/certs/ca-certificates.crt'
    # else
    #   raise "unsupported host OS for ssl sert file: #{Global::OS}"
    # end
  end

  # by default windres included with 64bit gcc toolchain (mingw) generates 64-bit obj files
  # we need to provide '-F pe-i386' to windres to generate 32bit output
  def fix_winres_params
    file = 'GNUmakefile'
    lines = []
    replaced = false
    File.foreach(file) do |l|
      if not l.start_with?('WINDRES = ')
        lines << l
      else
        lines << l.gsub('windres ', 'windres -F pe-i386 ')
        replaced = true
      end
    end

    raise "not found WINDRES line in GNUmakefile" unless replaced

    File.open(file, 'w') { |f| f.puts lines }
  end

  def fix_win_makefile
    file = 'Makefile'
    lines = []
    replaced = false
    File.foreach(file) do |l|
      if not l.include?('$(Q) $(LDSHARED) $(DLDFLAGS) $(OBJS) $(DLDOBJS) $(SOLIBS) $(EXTSOLIBS) $(OUTFLAG)$@')
        lines << l
      else
        lines << "\t\t$(Q) $(LDSHARED) $(DLDFLAGS) $(OBJS) $(DLDOBJS) $(SOLIBS) $(EXTSOLIBS) -lcrypt32 $(OUTFLAG)$@"
        replaced = true
      end
    end

    raise "not found required line in Makefile" unless replaced

    File.open(file, 'w') { |f| f.puts lines }
  end

  # to build ruby for windows platforms one must build and install ruby for linux platfrom
  # because here we need to run gem script and we can't run windows script on linux
  # and we can't relay on system's gem script because of subtle versions differences
  def gem_path(release, platform, install_dir)
    case platform.target_os
    when 'darwin', 'linux'
      "#{install_dir}/bin/gem"
    else
      "#{release_directory(release, 'linux-x86_64')}/bin/gem"
    end
  end
end
