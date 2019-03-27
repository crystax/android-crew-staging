class NetTools < Package

  name 'net-tools'
  desc 'A collection of programs that form the base set of the NET-3 networking distribution for the Linux operating system'
  homepage 'https://github.com/giftnuss/net-tools'
  url 'https://github.com/giftnuss/net-tools.git|commit:9446c4dd69fe5bc1c1de403039b9565fca9e4273'

  release '1.60', crystax: 4

  build_copy 'COPYING'
  build_options build_outside_source_tree: false,
                sysroot_in_cflags:    false,
                cflags_in_c_wrapper:  true,
                ldflags_in_c_wrapper: true,
                copy_installed_dirs:  ['bin', 'sbin'],
                gen_android_mk:       false

  def build_for_abi(abi, _toolchain, _release, _options)
    build_env['BASEDIR'] = install_dir_for_abi(abi)

    make
    make 'install'
  end
end
