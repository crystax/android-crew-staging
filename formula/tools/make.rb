class Make < Utility

  desc "Utility for directing compilation"
  homepage "https://www.gnu.org/software/make/"
  #url "https://ftpmirror.gnu.org/make/make-${version}.tar.bz2"

  release version: '3.81', crystax_version: 3

  def prepare_source_code(release, dir, src_name, log_prefix)
    # source code is in sources/host-tools/ directory
  end

  def build_for_platform(platform, release, options, _host_dep_dirs, _target_dep_dirs)
    src_dir = File.join(Build::NDK_HOST_TOOLS_DIR, "make-#{release.version}")
    install_dir = install_dir_for_platform(platform.name, release)

    args = platform.configure_args +
           ["--prefix=#{install_dir}",
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
