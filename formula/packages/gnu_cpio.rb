class GnuCpio < Package

  name 'gnu-cpio'
  desc "GNU cpio copies files into or out of a cpio or tar archive. The archive can be another file on the disk, a magnetic tape, or a pipe"
  homepage "https://www.gnu.org/software/cpio/"
  url "http://ftp.gnu.org/gnu/cpio/cpio-${version}.tar.bz2"

  release '2.12', crystax: 2

  build_options copy_installed_dirs: ['bin', 'lib', 'libexec'],
                gen_android_mk:      false

  build_copy 'COPYING'

  def build_for_abi(abi, _toolchain,  _release, _host_dep_dirs, _target_dep_dirs, _options)
    install_dir = install_dir_for_abi(abi)

    args =  [ "--prefix=#{install_dir}",
              "--host=#{host_for_abi(abi)}",
              "--disable-nls",
             " --disable-silent-rules"
            ]

    system './configure', *args
    system 'make', '-j', num_jobs
    system 'make', 'install'

    # remove unneeded files
    FileUtils.rm_rf File.join(install_dir, 'share')
  end
end
