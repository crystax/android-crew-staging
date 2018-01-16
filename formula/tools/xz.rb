class Xz < BuildDependency

  desc "General-purpose data compression with high compression ratio"
  homepage "http://tukaani.org/xz/"
  url "http://tukaani.org/xz/xz-${version}.tar.xz"

  release version: '5.2.3', crystax_version: 2

  def build_for_platform(platform, release, options, _host_dep_dirs, _target_dep_dirs)
    install_dir = install_dir_for_platform(platform.name, release)

    args = platform.configure_args +
           ["--prefix=#{install_dir}",
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
