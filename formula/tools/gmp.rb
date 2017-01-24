class Gmp < BuildDependency

  desc "GNU multiple precision arithmetic library"
  homepage "https://gmplib.org/"
  url "https://gmplib.org/download/gmp/gmp-${version}.tar.xz"

  release version: '6.1.1', crystax_version: 1, sha256: { linux_x86_64:   '8dc910c4bc2c33be21c6bc9b61cab90ac587454e712caa69bd4dbc827cd021d2',
                                                          darwin_x86_64:  'f2b7d2831d62d140c6761884198fee9e5d4c903b3fc2a897be525f41c2e1f303',
                                                          windows_x86_64: '61721509f25dad4fec8dc544b359a2467edef0f3d7fae9c202be05fcfb4fa955',
                                                          windows:        '7653cc5e414b82532fa6434078f2b3e98252dcb65314470a11b2c84be1d92cb4'
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
