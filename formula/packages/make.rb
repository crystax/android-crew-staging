class Make < Package

  desc "GNU make utility"
  homepage "https://www.gnu.org/software/make/"
  url "https://ftp.gnu.org/gnu/make/make-${version}.tar.bz2"

  release '4.2.1'

  build_copy 'COPYING'
  build_options copy_installed_dirs: ['bin', 'include'],
                gen_android_mk:      false


  def build_for_abi(abi, toolchain,  _release, _options)
    args = [ '--disable-silent-rules',
             '--disable-nls',
             '--disable-rpath'
           ]

    configure *args
    make
    make 'install'
  end
end
