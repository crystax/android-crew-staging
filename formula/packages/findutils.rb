class Findutils < Package

  desc 'The GNU Find Utilities are the basic directory searching utilities of the GNU operating system'
  homepage 'https://www.gnu.org/software/findutils/'
  url 'https://ftp.gnu.org/pub/gnu/findutils/findutils-${version}.tar.gz'

  release version: '4.6.0', crystax_version: 3

  build_copy 'COPYING'
  build_options copy_installed_dirs: ['bin', 'libexec'],
                gen_android_mk: false


  def build_for_abi(abi, _toolchain,  _release, _host_dep_dirs, _target_dep_dirs, _options)
    install_dir = install_dir_for_abi(abi)
    args = ["--prefix=#{install_dir}",
            "--host=#{host_for_abi(abi)}",
            "--disable-silent-rules",
            "--disable-rpath",
            "--disable-nls"
           ]

    system './configure', *args

    set_pthread_in_use_detection_hard 'config.h'

    system 'make', '-j', num_jobs
    system 'make', 'install'
  end
end
