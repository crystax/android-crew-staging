class Libedit < BuildDependency

  desc "BSD-style licensed readline alternative"
  homepage "http://thrysoee.dk/editline/"
  url "http://thrysoee.dk/editline/libedit-${version}.tar.gz"

  release version: '20150325-3.1', crystax_version: 1, sha256: { linux_x86_64:   '0',
                                                                 darwin_x86_64:  '0',
                                                                 windows_x86_64: '0',
                                                                 windows:        '0'

                                                               }
  # todo: version 20160618-3.1 fails to build on darwin

  def build_for_platform(platform, release, options, host_dep_dirs, _target_dep_dirs)
    install_dir = install_dir_for_platform(platform, release)

    args = ["--prefix=#{install_dir}",
            "--host=#{platform.configure_host}",
            "--enable-static",
            "--disable-shared",
            "--with-pic",
            "--enable-widec",
            "--disable-silent-rules",
            "--disable-dependency-tracking"
           ]

    system "#{src_dir}/configure", *args
    system 'make', '-j', num_jobs
    system 'make', 'check' if options.check? platform
    system 'make', 'install'

    # remove unneeded files before packaging
    FileUtils.cd(install_dir) { FileUtils.rm_rf ['share', 'lib/pkgconfig'] + Dir['lib/*.la'] }
  end
end
