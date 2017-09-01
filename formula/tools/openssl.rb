class Openssl < BuildDependency

  desc "Cryptography and SSL/TLS Toolkit"
  homepage "https://openssl.org/"
  url 'https://www.openssl.org/source/openssl-${version}.tar.gz'

  release version: '1.0.2l', crystax_version: 1
  # todo: add possibility to depend_on special version before uncommenting this
  # release version: '1.1.0b', crystax_version: 1

  depends_on 'zlib'

  def build_for_platform(platform, release, options, host_dep_dirs, _target_dep_dirs)
    install_dir = install_dir_for_platform(platform.name, release)
    zlib_dir = host_dep_dirs[platform.name]['zlib']

    FileUtils.cp_r File.join(src_dir, '.'), '.'

    zlib = (platform.target_os == 'windows') ? 'z.dll' : 'z'

    args = ["--prefix=#{install_dir}",
            "no-idea",
            "no-mdc2",
            "no-rc5",
            "shared",
            "zlib",
            openssl_platform(platform),
            platform.cflags,
            "-I#{zlib_dir}/include",
            "-L#{zlib_dir}/lib",
            "-l#{zlib}"
           ]

    # parallel build seems to be broken not only on darwin
    # it seems that parallel build is broken for all host systems now
    system './Configure',  *args
    system 'make', 'depend'
    system 'make'
    system 'make', 'test' if options.check? platform
    system "make install"

    FileUtils.cp ['libeay32.dll', 'ssleay32.dll'], File.join(install_dir, 'lib') if platform.target_os == 'windows'

    # remove unneeded files
    FileUtils.rm_rf File.join(install_dir, 'lib', 'pkgconfig')
    FileUtils.rm_rf File.join(install_dir, 'lib', 'engines')
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
end
