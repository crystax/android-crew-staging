class Libarchive < Utility

  name 'bsdtar'
  desc 'bsdtar utility from multi-format archive and compression library libarchive'
  homepage 'http://www.libarchive.org'
  url 'http://www.libarchive.org/downloads/libarchive-${version}.tar.gz'
  role :core

  release version: '3.1.2', crystax_version: 1, sha256: { linux_x86_64:   '0',
                                                          linux_x86:      '0',
                                                          darwin_x86_64:  '0',
                                                          darwin_x86:     '0',
                                                          windows_x86_64: '0',
                                                          windows:        '0'
                                                        }

  build_depends_on 'xz'

  def build_for_platform(platform, release, options, dep_dirs)
    install_dir = install_dir_for_platform(platform, release)
    xz_dir = dep_dirs[platform.name]['xz']

    build_env['CC']      = platform.cc
    build_env['CFLAGS']  = "-I#{xz_dir}/include #{platform.cflags}"
    build_env['LDFLAGS'] = "-L#{xz_dir}/lib"
    build_env['LANG']    = 'C'
    build_env['V']       = '1'

    #env['LDFLAGS'] = ' -ldl' if options.target_os == 'linux'
    args = ["--prefix=#{install_dir}",
            "--host=#{platform.configure_host}",
            "--disable-shared",
            "--without-iconv",
            "--without-nettle",
            "--without-xml2",
            "--without-expat",
            "--with-sysroot"
           ]
    system "#{src_dir}/configure", *args
    system 'make', '-j', num_jobs
    system 'make', 'check' if options.check? platform
    system 'make', 'install'
                                    
    # remove unneeded files
    FileUtils.rm_rf [File.join(install_dir, 'include'), File.join(install_dir, 'lib'), File.join(install_dir, 'share')]
    FileUtils.rm_f  File.join(install_dir, 'bin', 'bsdcpio')
  end
end
