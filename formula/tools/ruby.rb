class Ruby < Utility

  desc 'Powerful, clean, object-oriented scripting language'
  homepage 'https://www.ruby-lang.org/'
  url 'https://cache.ruby-lang.org/pub/ruby/${block}/ruby-${version}.tar.gz' do |r| r.version.split('.').slice(0, 2).join('.') end

  release '2.5.3'

  depends_on 'zlib'
  depends_on 'openssl'
  depends_on 'libssh2'
  depends_on 'libgit2'

  GEMS = {'rspec' => '3.7.0', 'minitar' => '0.6.1'}

  def wrapper_script_lines(_exe, platform_name)
    platform_name.start_with?('windows') ? ['set GEM_HOME=', 'set GEM_PATH='] : ['unset GEM_HOME', 'unset GEM_PATH']
  end

  def prepare_source_code(release, dir, src_name, log_prefix)
    super(release, dir, src_name, log_prefix)

    # todo: get installed libgit2 version and make rugged version out of it
    rugged_ver = '0.27.5'

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

    cppflags = "-I#{tools_dir}/include #{platform.cflags}"
    ldflags = "-w -L#{tools_dir}/lib"
    if platform.target_os != 'windows'
      libs = '-lz -lgit2 -lssh2 -lssl -lcrypto -lz'
    else
      cppflags += ' -D_FORTIFY_SOURCE=2 -D__USE_MINGW_ANSI_STDIO=1 -DFD_SETSIZE=2048'
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

    build_env['CPPFLAGS']        = cppflags
    build_env['LDFLAGS']         = ldflags
    build_env['LIBS']            = libs
    build_env['SSL_CERT_FILE']   = host_ssl_cert_file
    build_env['RUGGED_CFLAGS']   = "#{cppflags} -DRUBY_UNTYPED_DATA_WARNING=0 -I#{tools_dir}/include"
    build_env['RUGGED_MAKEFILE'] = "#{build_dir_for_platform(platform.name)}/ext/rugged/Makefile"
    build_env['DESTDIR']         = install_dir
    build_env['V']               = '1'

    if platform.target_os == 'windows'
      build_env['PATH']    = "#{platform.toolchain_path}:#{ENV['PATH']}"
      build_env['WINDRES'] = platform.windres
      build_env['DLLWRAP'] = platform.dllwrap
      build_env['STRIP']   = platform.strip
      # todo: remove when win32 build will be fixed
      build_env['CFLAGS'] += ' -ggdb' if platform.target_cpu == 'x86'
    end

    if platform.target_os == 'darwin'
      build_env['LDFLAGS'] += " -Wl,-rpath,#{tools_dir}/lib -F#{platform.sysroot}/System/Library/Frameworks"
    end

    # on linux using even the same --host and --build treated as crosscompiling which breaks build
    args  = (platform.target_os == 'linux') ? [] : platform.configure_args
    args += ["--prefix=/",
             "--disable-install-doc",
             "--enable-load-relative",
             "--disable-static",
             "--enable-shared",
             "--with-openssl-dir=#{tools_dir}",
             "--without-gmp",
             "--without-tk",
             "--without-gdbm",
             "--enable-bundled-libyaml"
            ]
    if platform.target_os == 'windows'
      args += ["--with-baseruby=#{Global::tools_dir('linux-x86_64')}/bin/ruby",
               "--with-out-ext=readline,pty,syslog"
              ]
      args << "--target=#{platform.configure_host}" if platform.target_cpu == 'x86'
    end

    Build.add_dyld_library_path "#{src_dir}/configure", "#{tools_dir}/lib" if platform.target_os == 'darwin'

    if platform.target_os == 'windows'
      FileUtils.cd(src_dir) do
        system 'autoreconf', '-fi'
        FileUtils.cd('ext/fiddle/libffi-3.2.1') { system 'autoreconf', '-fi' }
      end
    end
    system "#{src_dir}/configure", *args

    begin
      system 'make', 'V=1', '-j', num_jobs
    rescue
      # ext/fiddle fails to build for windows with some strange error and
      # then builds OK when make run second time
      if platform.name == 'windows'
        system 'make', 'V=1', '-j', num_jobs
      else
        raise
      end
    end

    system 'make', 'V=1', 'test' if options.check? platform
    system 'make', 'V=1', 'install'

    if platform.target_os == 'darwin'
      system 'install_name_tool', '-add_rpath', '@loader_path/../lib', "#{install_dir}/bin/ruby"
    end

    # remove unneeded files
    FileUtils.rm_rf File.join(install_dir, 'lib', 'pkgconfig')
    FileUtils.rm_rf File.join(install_dir, 'share')

    gem = gem_path(release, platform, install_dir)
    GEMS.each_pair { |name, version| install_gem gem, install_dir, name, version, release }
  end

  def install_gem(gem, install_dir, name, version, release)
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
            "--bindir #{install_dir}/bin",
            "--version #{version}"
           ]

    system gem, 'install', *args, name
  end

  def host_ssl_cert_file
    "#{Global::BASE_DIR}/etc/ca-certificates.crt"
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
    split_file_list_by_static_libs_and_includes(list, platform_name)
  end
end
