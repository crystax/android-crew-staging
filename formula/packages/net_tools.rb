class NetTools < Package

  name 'net-tools'
  desc 'A collection of programs that form the base set of the NET-3 networking distribution for the Linux operating system'
  homepage 'https://github.com/giftnuss/net-tools'
  url 'https://github.com/giftnuss/net-tools.git|git_commit:9446c4dd69fe5bc1c1de403039b9565fca9e4273'

  release version: '1.60', crystax_version: 1

  build_copy 'COPYING'
  build_options sysroot_in_cflags:    false,
                cflags_in_c_wrapper:  true,
                ldflags_in_c_wrapper: true,
                copy_installed_dirs:  ['bin', 'sbin'],
                gen_android_mk:       false

  def build_for_abi(abi, _toolchain, _release, _host_dep_dirs, _target_dep_dirs, _options)
    install_dir = install_dir_for_abi(abi)

    build_env['BASEDIR'] = install_dir

    system 'make', '-j', num_jobs
    system 'make', 'install'
  end
end
