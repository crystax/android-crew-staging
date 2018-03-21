class GnuWhich < Package

  name 'gnu-which'
  desc 'GNU which shows the full path of (shell) commands'
  homepage 'http://carlowood.github.io/which/index.html'
  url 'http://carlowood.github.io/which/which-${version}.tar.gz'

  release version: '2.21', crystax_version: 2

  build_copy 'COPYING'
  build_options copy_installed_dirs: ['bin'],
                gen_android_mk:      false

  def build_for_abi(abi, _toolchain, _release, _host_dep_dirs, _target_dep_dirs, _options)
    install_dir = install_dir_for_abi(abi)

    args =  ["--prefix=#{install_dir}",
             "--host=#{host_for_abi(abi)}",
             "--disable-silent-rules"
            ]

    system './configure', *args
    system 'make', '-j', num_jobs
    system 'make', 'install'
  end
end
