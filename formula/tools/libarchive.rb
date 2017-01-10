class Libarchive < Utility

  name 'bsdtar'
  desc 'bsdtar utility from multi-format archive and compression library libarchive'
  homepage 'http://www.libarchive.org'
  url 'http://www.libarchive.org/downloads/libarchive-${version}.tar.gz'

  release version: '3.2.0', crystax_version: 1, sha256: { linux_x86_64:   'a5499ae01a311c1d2c47b9d2231e045d3739d36d22da3c2d98e27f7173715f20',
                                                          darwin_x86_64:  'cf35ce53dab94ca800146c8be7ca3a9b823329e0a75f57cb0171db6608a75d94',
                                                          windows_x86_64: 'c9d8eddfd990d1b1d63fdbeaf8bb9848b1982a45654e793254926ee4f401a68a',
                                                          windows:        '34532411bd60d2f4edba594bc5657db8b06d5cb9f0b09539c9800b838ff1e901'
                                                        }

  build_depends_on 'xz'

  def build_for_platform(platform, release, options, host_dep_dirs, _target_dep_dirs)
    install_dir = install_dir_for_platform(platform, release)
    xz_dir = host_dep_dirs[platform.name]['xz']

    build_env['CFLAGS']  += " -I#{xz_dir}/include #{platform.cflags}"
    build_env['LDFLAGS']  = "-L#{xz_dir}/lib"

    #env['LDFLAGS'] = ' -ldl' if options.target_os == 'linux'
    args = ["--prefix=#{install_dir}",
            "--host=#{platform.configure_host}",
            "--disable-shared",
            "--without-iconv",
            "--without-nettle",
            "--without-xml2",
            "--without-expat",
            "--disable-silent-rules",
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
