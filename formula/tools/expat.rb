class Expat < BuildDependency

  desc "XML 1.0 parser"
  homepage "https://libexpat.github.io/"
  url 'https://dl.crystax.net/mirror/expat-${version}.tar.bz2'

  release '2.2.0', crystax: 5

  def build_for_platform(platform, release, options)
    install_dir = install_dir_for_platform(platform.name, release)

    args = platform.configure_args +
           ["--prefix=#{install_dir}",
            "--disable-shared"
           ]

    system "#{src_dir}/configure", *args
    system 'make', '-j', num_jobs
    system 'make', 'check' if options.check? platform
    system 'make', 'install'

    # remove unneeded files before packaging
    FileUtils.cd(install_dir) { FileUtils.rm_rf ['bin', 'share', 'lib/pkgconfig'] + Dir['lib/*.la'] }
  end
end
