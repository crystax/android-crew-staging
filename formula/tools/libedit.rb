class Libedit < BuildDependency

  desc "BSD-style licensed readline alternative"
  homepage "http://thrysoee.dk/editline/"
  url "http://thrysoee.dk/editline/libedit-${version}.tar.gz"

  # todo: version 20160618-3.1 fails to build on darwin
  release version: '20150325-3.1', crystax_version: 3

  def build_for_platform(platform, release, options, _host_dep_dirs, _target_dep_dirs)
    install_dir = install_dir_for_platform(platform.name, release)
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
