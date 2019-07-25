class Curl < Library

  desc 'Get a file from an HTTP, HTTPS or FTP server'
  homepage 'http://curl.haxx.se/'
  url 'https://curl.haxx.se/download/curl-${version}.tar.bz2'

  release '7.65.3'

  depends_on 'zlib'
  depends_on 'openssl'
  depends_on 'libssh2'

  postpone_install true

  def build_for_platform(platform, release, options)
    install_dir = install_dir_for_platform(platform.name, release)
    tools_dir   = Global::tools_dir(platform.name)

    build_env['LIBS']            = '-ldl'                   if platform.target_os == 'linux'
    build_env['LIBS']            = '-lcrypt32'              if platform.target_os == 'windows'
    build_env['CPPFLAGS']        = "-I#{tools_dir}/include"
    build_env['LDFLAGS']         = "-L#{tools_dir}/lib"
    build_env['LD_LIBRARY_PATH'] = "#{tools_dir}/lib"       if platform.target_os == 'linux'

    args  = platform.configure_args +
            ["--prefix=#{install_dir}",
             "--disable-silent-rules",
             "--disable-ldap",
             "--without-libidn2",
             "--with-ssl=#{tools_dir}",
             "--with-libssh2=#{tools_dir}"
            ]
    args += ['--disable-pthreads'] if platform.target_os == 'windows'

    Build.add_dyld_library_path "#{src_dir}/configure", "#{tools_dir}/lib" if platform.target_os == 'darwin'

    system "#{src_dir}/configure", *args
    system 'make', '-j', num_jobs
    system 'make', 'install'

    if options.check? platform
      fix_tests_makefile 'tests/Makefile', "#{tools_dir}/lib"
      system 'install_name_tool', '-add_rpath', "#{tools_dir}/lib", 'src/.libs/curl' if platform.target_os == 'darwin'
      system 'make', 'test'
    end

    # why dylib version is 4?
    if platform.target_os == 'darwin'
      ver = 4
      curl_lib = "libcurl.#{ver}.dylib"
      system 'install_name_tool', '-id', "@rpath/#{curl_lib}", "#{install_dir}/lib/#{curl_lib}"
      system 'install_name_tool', '-add_rpath', '@loader_path/../lib', "#{install_dir}/bin/curl"
      system 'install_name_tool', '-change', "#{install_dir}/lib/#{curl_lib}", "@rpath/#{curl_lib}", "#{install_dir}/bin/curl"
    end

    # remove unneeded files before packaging
    FileUtils.cd(install_dir) { FileUtils.rm_rf ['bin/curl-config', 'lib/pkgconfig', 'share'] + Dir['lib/*.la'] }
  end

  def split_file_list(list, platform_name)
    split_file_list_by_shared_libs(list, platform_name)
  end

  def fix_tests_makefile(makefile, rpath_dir)
    lines = []
    File.readlines(makefile).each do |l|
      l = l.rstrip + " -Wl,-rpath,#{rpath_dir}\n" if l =~ /$LDFLAGS =/
      lines << l
    end
    File.open(makefile, 'w') { |f| f.puts lines }
  end
end
