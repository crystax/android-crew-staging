class Ruby < Utility

  desc 'Powerful, clean, object-oriented scripting language'
  homepage 'https://www.ruby-lang.org/'
  url 'https://cache.ruby-lang.org/pub/ruby/${block}/ruby-${version}.tar.gz' do |r| r.version.split('.').slice(0, 2).join('.') end

  release version: '2.4.2', crystax_version: 1

  build_depends_on 'zlib'
  build_depends_on 'openssl'
  build_depends_on 'libssh2'
  build_depends_on 'libgit2'

  def wrapper_script_lines(_exe, platform_name)
    platform_name.start_with?('windows') ? ['set GEM_HOME=', 'set GEM_PATH='] : ['unset GEM_HOME', 'unset GEM_PATH']
  end

  def prepare_source_code(release, dir, src_name, log_prefix)
    super(release, dir, src_name, log_prefix)

    # todo: get installed libgit2 version and make rugged version out of it
    rugged_ver = '0.26.0'

    # download and unpack rugged sources
    rugged_url = "https://github.com/libgit2/rugged/archive/v#{rugged_ver}.tar.gz"
    rugged_archive = Formula.src_cache_file('rugged', Release.new(rugged_ver), rugged_url)
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
    install_dir = install_dir_for_platform(platform.name, release)
    tools_dir   = Global::tools_dir(platform.name)

    cflags  = "-I#{tools_dir}/include #{platform.cflags}"
    ldflags = "-w -L#{tools_dir}/lib"
    if platform.target_os != 'windows'
      libs = '-lz -lgit2 -lssh2 -lssl -lcrypto -lz'
    else
      libs = ["#{tools_dir}/lib/libgit2.dll.a",
              "#{tools_dir}/lib/libssh2.dll.a",
              "#{tools_dir}/lib/libssl.dll.a",
              "#{tools_dir}/lib/libcrypto.dll.a",
              "#{tools_dir}/lib/libz.dll.a",
              "-lws2_32",
              "-lcrypt32",
              "-lgdi32"
             ].join(' ')
    end

    build_env['CFLAGS']         += ' ' + cflags
    build_env['LDFLAGS']         = ldflags
    build_env['LIBS']            = libs
    build_env['SSL_CERT_FILE']   = host_ssl_cert_file
    build_env['RUGGED_CFLAGS']   = "#{cflags} -DRUBY_UNTYPED_DATA_WARNING=0 -I#{tools_dir}/include"
    build_env['RUGGED_MAKEFILE'] = "#{build_dir_for_platform(platform.name)}/ext/rugged/Makefile"
    build_env['DESTDIR']         = install_dir
    build_env['PATH']            = "#{platform.toolchain_path}:#{ENV['PATH']}" if platform.target_os == 'windows'

    if platform.target_os == 'darwin'
      build_env['LDFLAGS'] += " -Wl,-rpath,#{tools_dir}/lib -F#{platform.sysroot}/System/Library/Frameworks"
    end

    args = platform.configure_args +
           ["--prefix=/",
            "--disable-install-doc",
            "--enable-load-relative",
            "--enable-shared",
            "--with-openssl-dir=#{tools_dir}",
            "--without-gmp",
            "--without-tk",
            "--without-gdbm",
            "--enable-bundled-libyaml"
           ]
    args << "--with-baseruby=#{Global::tools_dir('linux-x86_64')}/bin/ruby" if platform.target_os == 'windows'

    Build.add_dyld_library_path "#{src_dir}/configure", "#{tools_dir}/lib" if platform.target_os == 'darwin'

    system "#{src_dir}/configure", *args
    fix_winres_params if platform.name == 'windows'
    fix_win_makefile  if platform.target_os == 'windows'

    system 'make', 'V=1', '-j', num_jobs
    system 'make', 'V=1', 'test' if options.check? platform
    system 'make', 'V=1', 'install'

    if platform.target_os == 'darwin'
      system 'install_name_tool', '-add_rpath', '@loader_path/../lib', "#{install_dir}/bin/ruby"
    end

    # remove unneeded files
    FileUtils.rm_rf File.join(install_dir, 'lib', 'pkgconfig')
    FileUtils.rm_rf File.join(install_dir, 'share')

    gem = gem_path(release, platform, install_dir)
    install_gem gem, install_dir, 'rspec', release
  end

  def install_gem(gem, install_dir, name, release)
    ver = release.version.split('.')
    ver[2] = '0'
    ruby_ver = ver.join('.')

    build_env.clear
    build_env['GEM_HOME'] = "#{install_dir}/lib/ruby/gems/#{ruby_ver}"
    build_env['GEM_PATH'] = "#{install_dir}/lib/ruby/gems/#{ruby_ver}"
    build_env['SSL_CERT_FILE'] = host_ssl_cert_file

    args = ['-V',
            '--no-document',
            '--backtrace',
            "--bindir #{install_dir}/bin"
           ]

    system gem, 'install', *args, name
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
        lines << l.gsub(/(.*-windres)/, '\1 -F pe-i386')
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
    when 'linux'
      "#{install_dir}/bin/gem"
    when 'darwin'
      if platform.host_os == 'darwin'
        "#{install_dir}/bin/gem"
      else
        "#{Global::tools_dir('linux-x86_64')}/bin/gem"
      end
    else
      "#{Global::tools_dir('linux-x86_64')}/bin/gem"
    end
  end

  def split_file_list(list, platform_name)
    # put binary files to bin list
    dev_list, bin_list = list.partition { |e| e =~ /(.*\.h)|(.*\.a)/ }
    # add directories to bin list
    dirs = []
    dev_list.each do |f|
      ds = File.dirname(f).split('/')
      dirs += (1..ds.size).map { |e| ds.first(e).join('/') }
    end
    dev_list += dirs.sort.uniq

    [bin_list.sort, dev_list.sort]
  end
end
