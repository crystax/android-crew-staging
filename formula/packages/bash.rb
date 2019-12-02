class Bash < Package

  desc "Bourne-Again SHell, a UNIX command interpreter"
  homepage "https://www.gnu.org/software/bash/"
  url "http://ftp.gnu.org/gnu/bash/bash-${version}.tar.gz"

  release '5.0', crystax: 3

  package_info root_dir: ['bin']

  build_copy 'COPYING'
  build_options use_standalone_toolchain: [],
                use_static_libcrystax: true,
                copy_installed_dirs: ['bin'],
                gen_android_mk:      false


  def build_for_abi(abi, toolchain,  _release, _options)
    args = [ "--enable-readline",
             "--enable-alias",
             "--enable-arith-for-command",
             "--enable-array-variables",
             "--enable-brace-expansion",
             "--enable-direxpand-default",
             "--enable-directory-stack",
             "--disable-nls",
             "--disable-rpath",
             "--without-bash-malloc",
             "--without-libintl-prefix",
             "--without-libiconv-prefix"
           ]

    configure *args
    make
    make 'install'

    # remove unneeded files
    FileUtils.rm File.join(install_dir_for_abi(abi), 'bin', 'bashbug')
  end
end
