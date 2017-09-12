class Curl < Utility

  desc 'Get a file from an HTTP, HTTPS or FTP server'
  homepage 'http://curl.haxx.se/'
  url 'https://curl.haxx.se/download/curl-${version}.tar.bz2'

  release version: '7.55.1', crystax_version: 1

  build_depends_on 'zlib'
  build_depends_on 'openssl'
  build_depends_on 'libssh2'

  def build_for_platform(platform, release, options, _host_dep_dirs, _target_dep_dirs)
    install_dir = install_dir_for_platform(platform.name, release)
    tools_dir   = Global::tools_dir(platform.name)

    #build_env['CPPFLAGS'] = "-DCURL_STATICLIB"
    build_env['LIBS']     = '-ldl'      if platform.target_os == 'linux'
    build_env['LIBS']     = '-lcrypt32' if platform.target_os == 'windows'

    build_env['CPPFLAGS'] = "-I#{tools_dir}/include"
    build_env['LDFLAGS']  = "-L#{tools_dir}/lib"


    args  = platform.configure_args +
            ["--prefix=#{install_dir}",
             "--disable-ldap"
            ]

    Build.add_dyld_library_path "#{src_dir}/configure", "#{tools_dir}/lib" if platform.target_os == 'darwin'

    system "#{src_dir}/configure", *args
    system 'make', '-j', num_jobs
    system 'make', 'install'

    if options.check? platform
       if platform.target_os == 'darwin'
         FileUtils.cp Dir["#{tools_dir}/lib/libz*.dylib"],      './tests/'
         FileUtils.cp Dir["#{tools_dir}/lib/libcrypto*.dylib"], './tests/'
         FileUtils.cp Dir["#{tools_dir}/lib/libssl*.dylib"],    './tests/'
       end
      system 'make', 'test'
    end

    # fix dylib install names on darwin
    # why dylib version is 4?
    if platform.target_os == 'darwin'
      ver = 4
      curl_lib = "libcurl.#{ver}.dylib"
      system 'install_name_tool', '-id', curl_lib, "#{install_dir}/lib/#{curl_lib}"
    end

    # remove unneeded files before packaging
    FileUtils.cd(install_dir) { FileUtils.rm_rf ['bin/curl-config', 'lib/pkgconfig', 'share'] + Dir['lib/*.la'] }
  end

  def split_file_list(list, platform_name)
    split_file_list_by_shared_libs(list, platform_name)
  end
end
