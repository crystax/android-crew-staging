class GnuTar < Package

  name 'gnu-tar'
  desc 'GNU Tar provides the ability to create tar archives, as well as various other kinds of manipulation'
  homepage 'https://www.gnu.org/software/tar/'
  url 'https://ftp.gnu.org/gnu/tar/tar-${version}.tar.xz'

  release version: '1.30', crystax_version: 1

  build_copy 'COPYING'
  build_options copy_installed_dirs: ['bin', 'libexec'],
                gen_android_mk:      false

  def build_for_abi(abi, _toolchain, _release, _host_dep_dirs, _target_dep_dirs, _options)
    install_dir = install_dir_for_abi(abi)

    args =  ["--prefix=#{install_dir}",
             "--host=#{host_for_abi(abi)}",
             "--disable-silent-rules",
             "--disable-nls"
            ]

    system './configure', *args
    system 'make', '-j', num_jobs, 'V=1'
    system 'make', 'install'
  end
end
