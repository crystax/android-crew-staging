class Libssh2 < Utility

  desc "A Massively Spiffy Yet Delicately Unobtrusive Compression Library"
  homepage 'http://www.libssh2.org/'
  url 'http://www.libssh2.org/download/libssh2-${version}.tar.gz'

  release version: '1.8.0', crystax_version: 2

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
    build_env['LIBS']     = "-lcrypt32 -lgdi32" if platform.target_os == 'windows'
    build_env['LIBS']     = "-ldl"              if platform.target_os == 'linux'

    build_env['LD_LIBRARY_PATH'] = "#{tools_dir}/lib" unless platform.target_os == 'windows'

    args = platform.configure_args +
           ["--prefix=#{install_dir}",
            "--disable-examples-build",
            "--with-libssl-prefix=#{tools_dir}",
            "--with-libz=#{tools_dir}"
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

  def split_file_list(list, platform_name)
    split_file_list_by_shared_libs(list, platform_name)
  end
end
