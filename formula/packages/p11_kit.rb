class P11Kit < Package

  name 'p11-kit'
  desc 'Provides a way to load and enumerate PKCS#11 modules'
  homepage 'https://p11-glue.github.io/p11-glue/p11-kit.html/'
  url 'https://github.com/p11-glue/p11-kit/releases/download/0.23.9/p11-kit-${version}.tar.gz'

  release version: '0.23.9', crystax_version: 3

  depends_on 'libffi'

  build_copy 'COPYING'
  build_options copy_installed_dirs: ['bin', 'etc', 'include', 'lib', 'libexec'],
                gen_android_mk:      false

  def build_for_abi(abi, _toolchain, _release, _host_dep_dirs, target_dep_dirs, _options)
    install_dir = install_dir_for_abi(abi)
    libffi_dir = target_dep_dirs['libffi']

    build_env['LIBFFI_CFLAGS'] = " -I#{libffi_dir}/include"
    build_env['LIBFFI_LIBS']   = " -L#{libffi_dir}/libs/#{abi} -lffi"

    args =  [ "--prefix=#{install_dir}",
              "--host=#{host_for_abi(abi)}",
              "--disable-silent-rules",
              "--enable-shared",
              "--disable-nls",
              "--disable-doc",
              "--with-pic",
              "--with-sysroot",
              "--without-libtasn1"
            ]

    system './configure', *args
    system 'make', '-j', num_jobs, 'V=1'
    system 'make', 'install'

    clean_install_dir abi, :lib
  end
end
