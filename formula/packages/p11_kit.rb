class P11Kit < Package

  name 'p11-kit'
  desc 'Provides a way to load and enumerate PKCS#11 modules'
  homepage 'https://p11-glue.github.io/p11-glue/p11-kit.html'
  url 'https://github.com/p11-glue/p11-kit/releases/download/${version}/p11-kit-${version}.tar.gz'

  release '0.23.16.1', crystax: 2

  depends_on 'libffi'

  build_copy 'COPYING'
  build_options copy_installed_dirs: ['bin', 'etc', 'include', 'lib', 'libexec'],
                gen_android_mk:      false

  def build_for_abi(abi, _toolchain, _release, _options)
    args =  [ "--disable-silent-rules",
              "--enable-shared",
              "--disable-nls",
              "--disable-doc",
              "--with-pic",
              "--with-sysroot",
              "--without-libtasn1"
            ]

    build_env['LIBFFI_CFLAGS'] = "-I#{target_dep_include_dir('libffi')}"
    build_env['LIBFFI_LIBS']   = "-L#{target_dep_lib_dir('libffi', abi)} -lffi"

    configure *args
    make
    make 'install'

    clean_install_dir abi
  end
end
