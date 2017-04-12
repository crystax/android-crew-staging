class Openssl < BuildDependency

  desc "Cryptography and SSL/TLS Toolkit"
  homepage "https://openssl.org/"
  url 'https://www.openssl.org/source/openssl-${version}.tar.gz'

  release version: '1.0.2k', crystax_version: 1, sha256: { linux_x86_64:   'c6671886250a6517efc203b87af6e50a6ac8da74a08d3ffb57c52d1c4f91d510',
                                                           darwin_x86_64:  '2cf65c48ca9adf478bd99723833715c67cd5e8c7b2928b72737d51bb8ca7da7a',
                                                           windows_x86_64: 'dcf9ac52f0b9dbb2b179a7c22eeb2c4e1aba6be98744fe420f25e1dd53deeec7',
                                                           windows:        'ce5958fe799bb08d91bf564d1e9a2eb8c175ff94ee6192e9ea005956313f8f0b'
                                                         }
  # todo: add possibility to depend_on specici version before uncommenting this
  # release version: '1.1.0b', crystax_version: 1, sha256: { linux_x86_64:   '0',
  #                                                          darwin_x86_64:  '0',
  #                                                          windows_x86_64: '0',
  #                                                          windows:        '0'
  #                                                        }

  depends_on 'zlib'

  def build_for_platform(platform, release, options, host_dep_dirs, _target_dep_dirs)
    install_dir = install_dir_for_platform(platform, release)
    zlib_dir = host_dep_dirs[platform.name]['zlib']

    FileUtils.cp_r File.join(src_dir, '.'), '.'

    args = ["--prefix=#{install_dir}",
            "no-idea",
            "no-mdc2",
            "no-rc5",
            "no-shared",
            "zlib",
            openssl_platform(platform),
            platform.cflags,
            "-I#{zlib_dir}/include",
            "-L#{zlib_dir}/lib",
            "-lz"
           ]

    # paralles build seems to be broken on darwin
    num_jobs = 1 if platform.host_os == 'darwin'

    system './Configure',  *args
    system 'make', 'depend'
    system 'make', '-j', num_jobs
    system 'make', 'test' if options.check? platform
    system "make install"

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
