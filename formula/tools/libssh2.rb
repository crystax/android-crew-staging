class Libssh2 < Utility

  desc "libssh2 is a client-side C library implementing the SSH2 protocol"
  homepage 'http://www.libssh2.org/'
  url 'http://www.libssh2.org/download/libssh2-${version}.tar.gz'

  release '1.8.0', crystax: 4

  depends_on 'zlib'
  depends_on 'openssl'

  def build_for_platform(platform, release, options, host_dep_dirs, _target_dep_dirs)
    install_dir = install_dir_for_platform(platform.name, release)
    tools_dir   = Global::tools_dir(platform.name)

    if platform.target_os == 'windows'
      crypto = 'crypto.dll'
      ssl    = 'ssl.dll'
      zlib   = 'z.dll'
    else
      crypto = 'crypto'
      ssl    = 'ssl'
      zlib = 'z'
    end

    build_env['CFLAGS']  += " -I#{tools_dir}/include #{platform.cflags}"
    build_env['LDFLAGS']  = "-L#{tools_dir}/lib -l#{ssl} -l#{crypto} -l#{zlib}"
    build_env['LIBS']     = "-lcrypt32 -lgdi32"                  if platform.target_os == 'windows'
    build_env['LDFLAGS']  = "-Wl,-rpath,@executable_path/../lib" if platform.target_os == 'darwin'

    if platform.target_os == 'linux'
      build_env['LIBS'] = "-ldl"
      build_env['LD_LIBRARY_PATH'] = "#{tools_dir}/lib"
    end

    args = platform.configure_args +
           ["--prefix=#{install_dir}",
            "--disable-examples-build",
            "--with-libssl-prefix=#{tools_dir}",
            "--with-libz=#{tools_dir}"
           ]

    Build.add_dyld_library_path "#{src_dir}/configure", "#{tools_dir}/lib" if platform.target_os == 'darwin'

    system "#{src_dir}/configure",  *args
    fix_tests_makefile 'tests/Makefile', "#{Dir.pwd}/tests" if platform.target_os == 'darwin'

    system 'make', '-j', num_jobs, 'V=1'
    system 'make', 'install'

    if options.check? platform
      FileUtils.cp Dir["#{tools_dir}/lib/*.dylib"], "./tests/" if platform.target_os == 'darwin'
      system 'make', 'check'
    end

    # fix dylib install names on darwin
    if platform.target_os == 'darwin'
      ver = release.version.split('.')[0]
      ssh2_lib = "libssh2.#{ver}.dylib"
      system 'install_name_tool', '-id', "@rpath/#{ssh2_lib}", "#{install_dir}/lib/#{ssh2_lib}"
    end

    # remove unneeded files
    FileUtils.rm_rf "#{install_dir}/lib/pkgconfig"
    FileUtils.rm_rf "#{install_dir}/share"
    FileUtils.rm_rf Dir["#{install_dir}/lib/*.la"]
  end

  def split_file_list(list, platform_name)
    split_file_list_by_shared_libs(list, platform_name)
  end

  def fix_tests_makefile(makefile, rpath_dir)
    lines = []
    simple_cmd = "\t$(AM_V_CCLD)$(LINK) $(simple_OBJECTS) $(simple_LDADD) $(LIBS)\n"
    ssh2_cmd = "\t$(AM_V_CCLD)$(LINK) $(ssh2_OBJECTS) $(ssh2_LDADD) $(LIBS)\n"
    File.readlines(makefile).each do |l|
      lines << l
      if l == simple_cmd or l == ssh2_cmd
        lines << "\tinstall_name_tool -add_rpath #{rpath_dir} .libs/$@\n"
      end
    end
    File.open(makefile, 'w') { |f| f.puts lines }
  end
end
