class GnuSed < Package

  name 'gnu-sed'
  desc "sed (stream editor) is a non-interactive command-line text editor"
  homepage "https://www.gnu.org/software/sed/"
  url "https://ftp.gnu.org/gnu/sed/sed-${version}.tar.xz"

  release '4.7', crystax: 2

  build_copy 'COPYING'
  build_options copy_installed_dirs: ['bin'],
                gen_android_mk:      false

  def build_for_abi(abi, _toolchain, _release, _options)
    args =  ["--disable-silent-rules",
             "--disable-nls",
             "--disable-i18n"
            ]

    configure *args
    make
    make 'install'
  end
end
