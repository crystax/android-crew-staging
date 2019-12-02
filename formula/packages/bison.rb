class Bison < Package

  desc "Bison is a general-purpose parser generator"
  homepage "https://www.gnu.org/software/bison/"
  url "https://ftp.gnu.org/gnu/bison/bison-${version}.tar.xz"

  release '3.4.1', crystax: 2

  build_copy 'COPYING'
  build_options copy_installed_dirs: ['bin', 'lib', 'share'],
                gen_android_mk:      false


  def build_for_abi(abi, toolchain,  _release, _options)
    args = [ '--disable-silent-rules',
             '--disable-rpath',
             '--disable-nls'
           ]

    configure *args
    make
    make 'install'

    # remove unneeded files
    FileUtils.cd("#{install_dir_for_abi(abi)}/share") { FileUtils.rm_r ['doc', 'info', 'man'] }
  end
end
