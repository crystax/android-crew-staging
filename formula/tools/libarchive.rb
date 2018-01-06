class Libarchive < Utility

  name 'bsdtar'
  desc 'bsdtar utility from multi-format archive and compression library libarchive'
  homepage 'http://www.libarchive.org'
  url 'http://www.libarchive.org/downloads/libarchive-${version}.tar.gz'

  # 3.3.2 fails to build for windows
  release version: '3.3.1', crystax_version: 1

  build_depends_on 'xz'

  def build_for_platform(platform, release, options, host_dep_dirs, _target_dep_dirs)
    install_dir = install_dir_for_platform(platform.name, release)
    xz_dir = host_dep_dirs[platform.name]['xz']

    build_env['CFLAGS']  += " -I#{xz_dir}/include #{platform.cflags}"
    build_env['LDFLAGS']  = "-L#{xz_dir}/lib"

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
    FileUtils.cd(install_dir) do
      FileUtils.rm_rf ['include', 'lib', 'share']
      FileUtils.cd('bin') do
        FileUtils.rm_f  Dir['bsdcpio*'] + Dir['bsdcat*']
      end
    end
  end
end
