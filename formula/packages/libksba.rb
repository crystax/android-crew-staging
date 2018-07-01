class Libksba < Package

  desc "A library to access X.509 certificates and CMS data"
  homepage "https://github.com/gpg/libksba"
  url "https://www.gnupg.org/ftp/gcrypt/libksba/libksba-${version}.tar.bz2"

  release '1.3.5'

  depends_on 'libgpg-error'

  build_copy 'COPYING', 'COPYING.GPLv2', 'COPYING.GPLv3', 'COPYING.LGPLv3'

  def build_for_abi(abi, _toolchain,  _release, _host_dep_dirs, target_dep_dirs, _options)
    install_dir = install_dir_for_abi(abi)
    libgpg_error_dir = target_dep_dirs['libgpg-error']

    build_env['GPG_ERROR_CFLAGS'] = target_dep_include_dir(libgpg_error_dir)
    build_env['GPG_ERROR_LIBS']   = target_dep_lib_dir(libgpg_error_dir, abi) + ' ' + '-lgpg-error'

    build_env['CFLAGS']  += ' ' + build_env['GPG_ERROR_CFLAGS']
    build_env['LDFLAGS'] += ' ' + build_env['GPG_ERROR_LIBS']

    args =  [ "--prefix=#{install_dir}",
              "--host=#{host_for_abi(abi)}",
              "--disable-silent-rules",
              "--enable-shared",
              "--enable-static",
              "--disable-doc",
              "--with-pic",
              "--with-sysroot"
            ]

    system './configure', *args
    system 'make', '-j', num_jobs
    system 'make', 'install'

    clean_install_dir abi, :lib
  end
end
