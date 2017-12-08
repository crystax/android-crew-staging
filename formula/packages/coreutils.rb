class Coreutils < Package

  desc "GNU File, Shell, and Text utilities"
  homepage "https://www.gnu.org/software/coreutils"
  url "http://ftpmirror.gnu.org/coreutils/coreutils-${version}.tar.xz"

  release version: '8.27', crystax_version: 2

  build_options copy_installed_dirs: ['bin'],
                check_sonames:       false,
                gen_android_mk:      false

  build_copy 'COPYING'

  def build_for_abi(abi, _toolchain,  _release, _host_dep_dirs, _target_dep_dirs, _options)
    install_dir = install_dir_for_abi(abi)
    args =  [ "--prefix=#{install_dir}",
              "--host=#{host_for_abi(abi)}",
	      "--enable-single-binary=symlinks",
	      "--disable-nls",
	      "--disable-rpath",
	      "--without-selinux",
	      "--without-gmp",
	      "--without-libiconv-prefix",
	      "--without-libpth-prefix",
	      "--without-libintl-prefix"
            ]

    FileUtils.touch 'configure'

    system './configure', *args
    system 'make', '-j', num_jobs, 'V=1'
    system 'make', 'install-exec'

    # remove unneeded files
    FileUtils.cd(install_dir) do
      files = Dir['bin/*']
      files.delete('bin/coreutils')
      FileUtils.rm files
    end
  end
end
