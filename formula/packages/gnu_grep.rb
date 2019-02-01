class GnuGrep < Package

  name 'gnu-grep'
  desc "Grep searches one or more input files for lines containing a match to a specified pattern"
  homepage "https://www.gnu.org/software/grep/"
  url "https://ftp.gnu.org/gnu/grep/grep-${version}.tar.xz"

  release '3.3'

  build_copy 'COPYING'
  build_options copy_installed_dirs: ['bin'],
                gen_android_mk:      false

  def build_for_abi(abi, _toolchain, _release, _options)
    args =  [ "--disable-silent-rules", "--disable-nls" ]
    configure *args
    make
    make 'install'
  end
end
