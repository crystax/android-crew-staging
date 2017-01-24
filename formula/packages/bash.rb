class Bash < Package

  desc "Bourne-Again SHell, a UNIX command interpreter"
  homepage "https://www.gnu.org/software/bash/"
  url "http://ftp.gnu.org/gnu/bash/bash-${version}.tar.gz"

  release version: '4.3.30', crystax_version: 1, sha256: 'd3f40ea5304d136048de7083b601a17669518da9fd6c0f9f4fe9bf8e8148da1f'

  build_options copy_installed_dirs: ['bin'],
                gen_android_mk:      false

  build_copy 'COPYING'

  def build_for_abi(abi, _toolchain,  _release, _host_dep_dirs, _target_dep_dirs)
    args =  [ "--prefix=#{install_dir_for_abi(abi)}",
              "--host=#{host_for_abi(abi)}",
              "--disable-nls",
              "--enable-readline",
              "--enable-alias",
              "--enable-arith-for-command",
              "--enable-array-variables",
              "--enable-brace-expansion",
              "--enable-direxpand-default",
              "--enable-directory-stack",
              "--without-bash-malloc",
              "--without-libintl-prefix",
              "--without-libiconv-prefix"
            ]

    system './configure', *args
    system 'make', '-j', num_jobs
    system 'make', 'install'

    # remove unneeded files
    FileUtils.rm File.join(install_dir_for_abi(abi), 'bin', 'bashbug')
  end
end
