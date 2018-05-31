class GnuPg < Package

  name 'gnu-pg'
  desc "GnuPG is a complete and free implementation of the OpenPGP standard as defined by RFC4880 (also known as PGP)"
  homepage "https://www.gnupg.org"
  url "https://www.gnupg.org/ftp/gcrypt/gnupg/gnupg-${version}.tar.bz2"

  release version: '2.2.7', crystax_version: 1

  depends_on 'sqlite'
  depends_on 'npth'
  depends_on 'ncurses'
  depends_on 'readline'
  depends_on 'gnu-tls'
  depends_on 'libgpg-error'
  depends_on 'libassuan'
  depends_on 'libksba'
  depends_on 'libgcrypt'
  depends_on 'pinentry'

  build_copy 'COPYING'
  build_options use_standalone_toolchain: true,
                copy_installed_dirs: ['bin', 'libexec', 'sbin', 'share'],
                gen_android_mk:      false


  def build_for_abi(abi, toolchain,  _release, _host_dep_dirs, target_dep_dirs, _options)
    install_dir = install_dir_for_abi(abi)

    build_env['GPG_ERROR_VERSION'] = Formulary.new['target/libgpg-error'].highest_installed_release.version
    build_env['LIBASSUAN_VERSION'] = Formulary.new['target/libassuan'].highest_installed_release.version
    build_env['KSBA_VERSION'] = Formulary.new['target/libksba'].highest_installed_release.version
    build_env['LIBGCRYPT_VERSION'] = Formulary.new['target/libksba'].highest_installed_release.version

    lib = (abi == 'mips64') ? 'lib64' : 'lib'
    cflags  = toolchain.gcc_cflags(abi) + " -I#{toolchain.sysroot_dir}/usr/include"
    ldflags = toolchain.gcc_ldflags(abi) + " -L#{toolchain.sysroot_dir}/usr/#{lib}"
    cflags += ' -Wl,--no-warn-mismatch' if abi == 'armeabi-v7a-hard'

    arch = Build.arch_for_abi(abi)

    gnutls_libs = Build::BAD_ABIS.include?(abi) ? ' -lp11-kit -lidn2 -lunistring -lnettle -lhogweed -lffi -lgmp -lz ' : ' '

    build_env['CFLAGS']      = cflags
    build_env['LDFLAGS']     = ldflags
    build_env['LIBS']        =  '-lgcrypt -lksba -lassuan -lgpg-error -lgnutls' + gnutls_libs + '-lreadline -lncursesw -lnpth -lsqlite3'
    build_env['PATH']        = Build.path
    build_env['LC_MESSAGES'] = 'C'
    build_env['CC']          = toolchain.gcc
    build_env['CPP']         = "#{toolchain.gcc} #{cflags} -E"
    build_env['AR']          = toolchain.tool(arch, 'ar')
    build_env['RANLIB']      = toolchain.tool(arch, 'ranlib')
    build_env['READELF']     = toolchain.tool(arch, 'readelf')
    build_env['STRIP']       = toolchain.tool(arch, 'strip')

    args =  [ "--prefix=#{install_dir}",
              "--host=#{host_for_abi(abi)}",
              "--disable-silent-rules",
              "--disable-doc",
              "--enable-tofu",
              "--disable-ldap",
              "--disable-rpath",
              "--disable-nls",
            ]

    system './configure', *args
    system 'make', '-j', num_jobs
    system 'make', 'install'

    FileUtils.cd(install_dir) { FileUtils.rm_rf 'share/doc' }
  end
end
