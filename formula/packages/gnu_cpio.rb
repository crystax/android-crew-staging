class GnuCpio < Package

  name 'gnu-cpio'
  desc "GNU cpio copies files into or out of a cpio or tar archive. The archive can be another file on the disk, a magnetic tape, or a pipe"
  homepage "https://www.gnu.org/software/cpio/"
  url "https://ftp.gnu.org/gnu/cpio/cpio-${version}.tar.bz2"

  release '2.12', crystax: 4

  build_options copy_installed_dirs: ['bin', 'lib', 'libexec'],
                gen_android_mk:      false

  build_copy 'COPYING'

  def build_for_abi(abi, _toolchain,  _release, _options)
    args =  [ "--disable-nls", " --disable-silent-rules" ]
    configure *args
    make
    make 'install'
  end
end
