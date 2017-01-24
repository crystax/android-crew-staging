class Expat < BuildDependency

  desc "XML 1.0 parser"
  homepage "http://expat.sourceforge.net"
  url "https://downloads.sourceforge.net/project/expat/expat/${version}/expat-${version}.tar.bz2"

  release version: '2.2.0', crystax_version: 1, sha256: { linux_x86_64:   'e4b1acfcd9da25872e854878d569d512e5f2b9749c957522fee411efa44a657f',
                                                          darwin_x86_64:  '9643910c15323695200b26d482dc8085870a5ab1229922001dc7c9aeabca5300',
                                                          windows_x86_64: 'e90d3aa47754327ca38df8c019cc42f6ea582c8fe8fe1f2cd15e13b2c99beaf6',
                                                          windows:        '47c8d533a6f96bb857516fbbfce39ee6182897cf4b35d589cef71f5f052d2074'
                                                        }


  def build_for_platform(platform, release, options, _host_dep_dirs, _target_dep_dirs)
    install_dir = install_dir_for_platform(platform, release)

    args = ["--prefix=#{install_dir}",
            "--host=#{platform.configure_host}",
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
