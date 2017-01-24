class Libedit < BuildDependency

  desc "BSD-style licensed readline alternative"
  homepage "http://thrysoee.dk/editline/"
  url "http://thrysoee.dk/editline/libedit-${version}.tar.gz"

  release version: '20150325-3.1', crystax_version: 1, sha256: { linux_x86_64:   'f4544a32dbe933c269301ef6ea4ee44f0929470e5e10df56161dcd9e00b7d8ec',
                                                                 darwin_x86_64:  '802e12ecd4a6aa9c2ef2970ba05cf6ca153b4d1cfeb2738d35d938af58e014a5',
                                                                 windows_x86_64: 'e755520925e4ad279cdb97bca1f7feb948fbacb442db4c1f1a04893d3ded87aa',
                                                                 windows:        'c44470d728df69067bae6d40bcb2ab68f06de808685316acf8afc482a8c019a9'

                                                               }
  # todo: version 20160618-3.1 fails to build on darwin

  def build_for_platform(platform, release, options, _host_dep_dirs, _target_dep_dirs)
    install_dir = install_dir_for_platform(platform, release)
    if platform.target_os == 'windows'
      # create dummy package to satisfy build dependency
      FileUtils.touch "#{install_dir}/dummy_package"
      return
    end

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
