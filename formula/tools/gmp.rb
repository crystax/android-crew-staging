class Gmp < BuildDependency

  desc "GNU multiple precision arithmetic library"
  homepage "https://gmplib.org/"
  url "https://gmplib.org/download/gmp/gmp-${version}.tar.xz"

  release version: '6.1.1', crystax_version: 1, sha256: { linux_x86_64:   '14bab0ee958748dfb2f937c5ed8e6aa97bfb4ac91aa2e058a80f9bb642614108',
                                                          darwin_x86_64:  'f2b7d2831d62d140c6761884198fee9e5d4c903b3fc2a897be525f41c2e1f303',
                                                          windows_x86_64: '1beda47e70bca920aa09d43d7a8b6a0e212a9acc09225a14c9b15e5d08c5b63a',
                                                          windows:        'c40aea930c31cb4927dbfe77b3133648fc14f849b80548b05fffaacdc7df3252'
                                                        }

  def build_for_platform(platform, release, options, _host_deps_dirs, _target_dep_dirs)
    install_dir = install_dir_for_platform(platform, release)

    args = ["--prefix=#{install_dir}",
            "--host=#{platform.configure_host}",
            "--enable-cxx",
            "--disable-shared"
           ]
    args << 'ABI=32'             if platform.target_name == 'windows'
    args << '--disable-assembly' if platform.target_os == 'darwin'

    system "#{src_dir}/configure", *args
    system 'make', '-j', num_jobs
    system 'make', 'check' if options.check? platform
    system 'make', 'install'

    # remove unneeded files before packaging
    FileUtils.cd(install_dir) { FileUtils.rm_rf ['share'] + Dir['lib/*.la'] }
  end
end
