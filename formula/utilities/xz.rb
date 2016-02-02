class Xz < Utility

  desc "General-purpose data compression with high compression ratio"
  homepage "http://tukaani.org/xz/"
  url "http://tukaani.org/xz/xz-${version}.tar.xz"

  release version: '5.2.2', crystax_version: 1, sha256: { linux_x86_64:   '0',
                                                          linux_x86:      '0',
                                                          darwin_x86_64:  '0',
                                                          darwin_x86:     '0',
                                                          windows_x86_64: '0',
                                                          windows:        '0'
                                                        }

  def build_for_platform(platform, release, options, _)
    install_dir = install_dir_for_platform(platform, release)

    build_env['CC']     = platform.cc
    build_env['CFLAGS'] = platform.cflags
    build_env['LANG']   = 'C'

    # case platform.target_os
    # when 'windows'
    #   env['PATH'] = Builder.toolchain_path_and_path(options)
    #   env['RC'] = "x86_64-w64-mingw32-windres -F pe-i386" if options.target_cpu == 'x86'
    # end

    args = ["--prefix=#{install_dir}",
            "--host=#{platform.configure_host}",
            "--disable-nls",
            "--disable-xzdec",
            "--disable-lzmadec",
            "--disable-lzmainfo",
            "--disable-lzma-links",
            "--disable-scripts",
            "--disable-doc",
            "--disable-shared",
            "--with-sysroot"
           ]
    system "#{src_dir}/configure", *args
    system 'make', '-j', num_jobs
    system 'make', 'check' if options.check? platform
    system 'make', 'install'

    # remove unneeded files before packaging
    FileUtils.cd(install_dir) { FileUtils.rm_rf ['bin/unxz', 'bin/xzcat', 'lib/liblzma.la', 'lib/pkgconfig', 'share'] }
  end
end
