class Openssl < Utility

  desc "Cryptography and SSL/TLS Toolkit"
  homepage "https://openssl.org/"
  url 'https://www.openssl.org/source/openssl-${version}.tar.gz'

  #release version: '1.0.2l', crystax_version: 1
  # todo: add possibility to depend_on special version before uncommenting this
  release version: '1.1.0f', crystax_version: 1

  depends_on 'zlib'

  def build_for_platform(platform, release, options, host_dep_dirs, _target_dep_dirs)
    install_dir = install_dir_for_platform(platform.name, release)
    tools_dir = Global.tools_dir(platform.name)

    FileUtils.cp_r File.join(src_dir, '.'), '.'

    zlib = (platform.target_os == 'windows') ? 'z.dll' : 'z'

    args = ["--prefix=#{install_dir}",
            "--with-zlib-include=#{tools_dir}/include",
            "--with-zlib-lib=#{tools_dir}/lib",
            "no-dynamic-engine",
            "no-engine",
            "no-idea",
            "no-mdc2",
            "no-rc5",
            "shared",
            "zlib",
            openssl_platform(platform),
            platform.cflags,
            "-l#{zlib}"
           ]

    system './Configure',  *args
    system 'make', 'depend'
    system 'make', '-j', num_jobs
    system "make install"

    if options.check? platform
      FileUtils.cp Dir["#{tools_dir}/lib/libz*.dylib"], './test/' if platform.target_os == 'darwin'
      fix_shlib_wrap_sh "#{tools_dir}/lib"
      system 'make', 'test'
    end

    # fix dylib install names on darwin
    if platform.target_os == 'darwin'
      ver = release.version.split('.').first(2).join('.')
      crypto_lib = "libcrypto.#{ver}.dylib"
      ssl_lib = "libssl.#{ver}.dylib"
      system 'install_name_tool', '-id', "@rpath/#{crypto_lib}", "#{install_dir}/lib/#{crypto_lib}"
      system 'install_name_tool', '-id', "@rpath/#{ssl_lib}",    "#{install_dir}/lib/#{ssl_lib}"
      system 'install_name_tool', '-change', "#{install_dir}/lib/#{crypto_lib}", "@rpath/#{crypto_lib}", "#{install_dir}/lib/#{ssl_lib}"
    end

    # remove unneeded files
    if platform.target_os == 'windows'
      FileUtils.rm_rf Dir["#{install_dir}/bin/c_rehash*", "#{install_dir}/bin/openssl*"]
    else
      FileUtils.rm_rf "#{install_dir}/bin"
    end
    FileUtils.rm_rf Dir["#{install_dir}/lib/engines*"]
    FileUtils.rm_rf "#{install_dir}/lib/pkgconfig"
    FileUtils.rm_rf "#{install_dir}/share"
    FileUtils.rm_rf "#{install_dir}/ssl"
  end

  def openssl_platform(platform)
    case platform.name
    when 'darwin-x86_64'  then 'darwin64-x86_64-cc'
    when 'darwin-x86'     then 'darwin-i386-cc'
    when 'linux-x86_64'   then 'linux-x86_64'
    when 'linux-x86'      then 'linux-generic32'
    when 'windows-x86_64' then 'mingw64'
    when 'windows'        then 'mingw'
    else
      raise "unknown platform #{platform.name}"
    end
  end

  def split_file_list(list, platform_name)
    split_file_list_by_shared_libs(list, platform_name)
  end

  # DYLD_LIBRARY_PATH="${THERE}:$DYLD_LIBRARY_PATH" # MacOS X
  def fix_shlib_wrap_sh(lib_dir)
    fname = 'util/shlib_wrap.sh'
    text = File.read(fname).gsub(/^(\s+DYLD_LIBRARY_PATH="\${THERE}:)(\$DYLD_LIBRARY_PATH"\s+# MacOS X$)/, '\1' + "#{lib_dir}:" + '\2')
    File.open(fname, "w") {|f| f.puts text }
  end
end
