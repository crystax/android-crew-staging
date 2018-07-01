class Bash < Package

  desc "Bourne-Again SHell, a UNIX command interpreter"
  homepage "https://www.gnu.org/software/bash/"
  url "http://ftp.gnu.org/gnu/bash/bash-${version}.tar.gz"

  release '4.4.18', crystax: 2

  package_info root_dir: ['bin']

  build_copy 'COPYING'
  build_options use_standalone_toolchain: [],
                use_static_libcrystax: true,
                copy_installed_dirs: ['bin'],
                gen_android_mk:      false


  def build_for_abi(abi, toolchain,  _release, _host_dep_dirs, _target_dep_dirs, _options)
    install_dir = install_dir_for_abi(abi)

    # todo: remove when package will be able setup build_env for standalone toolchains too
    arch = Build.arch_for_abi(abi)
    cflags  = toolchain.gcc_cflags(abi)
    ldflags = toolchain.gcc_ldflags(abi)
    cc = "#{toolchain.gcc} --sysroot=#{toolchain.sysroot_dir}"

    build_env['LC_MESSAGES'] = 'C'
    build_env['CC']          = cc
    build_env['CPP']         = "#{cc} #{cflags} -E"
    build_env['AR']          = toolchain.tool(arch, 'ar')
    build_env['RANLIB']      = toolchain.tool(arch, 'ranlib')
    build_env['READELF']     = toolchain.tool(arch, 'readelf')
    build_env['STRIP']       = toolchain.tool(arch, 'strip')
    build_env['CFLAGS']      = cflags
    build_env['LDFLAGS']     = ldflags

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

    system './configure', *args
    system 'make', '-j', num_jobs
    system 'make', 'install'

    # remove unneeded files
    FileUtils.rm File.join(install_dir, 'bin', 'bashbug')
  end
end
