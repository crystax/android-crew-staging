class Gmp < BuildDependency

  desc "GNU multiple precision arithmetic library"
  homepage "https://gmplib.org/"
  url "https://gmplib.org/download/gmp/gmp-${version}.tar.xz"

  release '6.1.2', crystax: 4

  def build_for_platform(platform, release, options)
    install_dir = install_dir_for_platform(platform.name, release)

    args = ["--host=#{platform.configure_host}",
            "--build=#{platform.configure_build}",
            "--prefix=#{install_dir}",
            "--enable-cxx",
            "--disable-shared"
           ]
    args += ['ABI=32']             if platform.target_name == 'windows'
    args += ['--disable-assembly'] if platform.target_os == 'darwin'

    system "#{src_dir}/configure", *args
    system 'make', '-j', num_jobs
    system 'make', 'check' if options.check? platform
    system 'make', 'install'

    # remove unneeded files before packaging
    FileUtils.cd(install_dir) { FileUtils.rm_rf ['share'] + Dir['lib/*.la'] }
  end
end
