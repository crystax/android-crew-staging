class Libarchive < Utility

  name 'bsdtar'
  desc 'bsdtar utility from multi-format archive and compression library libarchive'
  homepage 'http://www.libarchive.org'
  url 'http://www.libarchive.org/downloads/libarchive-${version}.tar.gz'

  release version: '3.3.1', crystax_version: 1, sha256: { linux_x86_64:   '3c32292566dd9236b8d383d74d0e83a4a9731b4e2a2161caa20811d2d38cb205',
                                                          darwin_x86_64:  '4a46951fd63c22b5e9097ca9e00fd5b3f07158dd4ce04a78ac2a78f5c12ce809',
                                                          windows_x86_64: 'a133293cec3b70d76b74164545720c726bc12f7f12924b6238054c7a741aa1b5',
                                                          windows:        '91212ed23b896f02249372c3ebfead630a1b8254e06da4f3c9ad8ede8d10c1a1'
                                                        }

  build_depends_on 'xz'

  def build_for_platform(platform, release, options, host_dep_dirs, _target_dep_dirs)
    install_dir = install_dir_for_platform(platform, release)
    xz_dir = host_dep_dirs[platform.name]['xz']

    build_env['CFLAGS']  += " -I#{xz_dir}/include #{platform.cflags}"
    build_env['LDFLAGS']  = "-L#{xz_dir}/lib"

    #env['LDFLAGS'] = ' -ldl' if options.target_os == 'linux'
    args = platform.configure_args +
           ["--prefix=#{install_dir}",
            "--disable-shared",
            "--without-iconv",
            "--without-nettle",
            "--without-xml2",
            "--without-expat",
            "--disable-silent-rules",
            "--with-sysroot"
           ]

    # todo: remove when fixed upstream
    args << '--disable-acl' if platform.host_os == 'darwin'

    system "#{src_dir}/configure", *args
    system 'make', '-j', num_jobs
    system 'make', 'check' if options.check? platform
    system 'make', 'install'

    # remove unneeded files
    FileUtils.rm_rf [File.join(install_dir, 'include'), File.join(install_dir, 'lib'), File.join(install_dir, 'share')]
    FileUtils.rm_f  File.join(install_dir, 'bin', 'bsdcpio')
  end
end
