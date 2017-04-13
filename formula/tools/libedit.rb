class Libedit < BuildDependency

  desc "BSD-style licensed readline alternative"
  homepage "http://thrysoee.dk/editline/"
  url "http://thrysoee.dk/editline/libedit-${version}.tar.gz"

  release version: '20150325-3.1', crystax_version: 1, sha256: { linux_x86_64:   'ced36c2638caa5efd4ad8c4760bfa73445561b7c8aecc1ff1db3a14b0f373dbe',
                                                                 darwin_x86_64:  '802e12ecd4a6aa9c2ef2970ba05cf6ca153b4d1cfeb2738d35d938af58e014a5',
                                                                 windows_x86_64: '8baa4b5d20decefe568a41fc0b8efc2bd5d57146cf6044e2761922ecdeffe8ed',
                                                                 windows:        'cc4075972f9af7f7ef26d5282fb73cdd4c33e969e3dd1f025afc69866aac178e'
                                                               }
  # todo: version 20160618-3.1 fails to build on darwin

  def build_for_platform(platform, release, options, _host_dep_dirs, _target_dep_dirs)
    install_dir = install_dir_for_platform(platform, release)
    if platform.target_os == 'windows'
      # create dummy package to satisfy build dependency
      FileUtils.touch "#{install_dir}/dummy_package"
      return
    end

    args = platform.configure_args +
           ["--prefix=#{install_dir}",
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
