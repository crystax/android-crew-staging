class GnuSed < Package

  name 'gnu-sed'
  desc "sed (stream editor) is a non-interactive command-line text editor"
  homepage "https://www.gnu.org/software/sed/"
  url "https://ftp.gnu.org/gnu/sed/sed-${version}.tar.xz"

  release version: '4.4', crystax_version: 1

  build_copy 'COPYING'
  build_options copy_installed_dirs: ['bin'],
                gen_android_mk:      false

  def build_for_abi(abi, _toolchain, _release, _host_dep_dirs, _target_dep_dirs, _options)
    install_dir = install_dir_for_abi(abi)

    args =  ["--prefix=#{install_dir}",
             "--host=#{host_for_abi(abi)}",
             "--disable-silent-rules",
             "--disable-nls",
             "--disable-i18n"
            ]

    system './configure', *args
    system 'make', '-j', num_jobs
    system 'make', 'install'
  end
end
