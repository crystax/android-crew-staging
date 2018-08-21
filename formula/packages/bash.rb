class Bash < Package

  desc "Bourne-Again SHell, a UNIX command interpreter"
  homepage "https://www.gnu.org/software/bash/"
  url "http://ftp.gnu.org/gnu/bash/bash-${version}.tar.gz"

  release '4.4.18', crystax: 4

  package_info root_dir: ['bin']

  build_copy 'COPYING'
  build_options use_standalone_toolchain: [],
                use_static_libcrystax: true,
                copy_installed_dirs: ['bin'],
                gen_android_mk:      false


  def build_for_abi(abi, toolchain,  _release, _options)
    install_dir = install_dir_for_abi(abi)

    args =  [ "--prefix=#{install_dir}",
              "--host=#{host_for_abi(abi)}",
              "--enable-readline",
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
    FileUtils.rm File.join(install_dir, 'bin', 'bashbug')
  end
end
