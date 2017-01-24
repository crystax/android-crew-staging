class Make < Utility

  desc "Utility for directing compilation"
  homepage "https://www.gnu.org/software/make/"
  #url "https://ftpmirror.gnu.org/make/make-${version}.tar.bz2"

  release version: '3.81', crystax_version: 1, sha256: { linux_x86_64:   'a169f2b40f50de30a9d1ee42f1d9096244f4f4e85578bc4d6544b410a8ab4cc1',
                                                         darwin_x86_64:  '2ba0cda0313b6474a6017b96c9fa3889d07763102096bbaf585f65e64fcb093a',
                                                         windows_x86_64: 'fe97b9c79bcf996a06688d5aa91e3d033a450cecbf81c1e1970660f0ec22db18',
                                                         windows:        '1d289c2f7ebd45e14113530cfc34ea7c0941c6a1fd2e5b441649fce8420dde81'
                                                       }

  executables 'make'

  def prepare_source_code(release, dir, src_name, log_prefix)
    # source code is in sources/host-tools/ directory
  end

  def build_for_platform(platform, release, options, _host_dep_dirs, _target_dep_dirs)
    src_dir = File.join(Build::NDK_HOST_TOOLS_DIR, "make-#{release.version}")
    install_dir = install_dir_for_platform(platform, release)

    args = ["--prefix=#{install_dir}",
            "--host=#{platform.configure_host}",
            "--disable-nls",
            "--disable-rpath"
           ]

    system "#{src_dir}/configure", *args
    system 'make', '-j', num_jobs
    system 'make', 'test' if options.check? platform
    system 'make', 'install'

    # remove unneeded files before packaging
    FileUtils.cd(install_dir) { FileUtils.rm_rf 'share' }
  end
end
