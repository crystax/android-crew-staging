class GnuWhich < Package

  name 'gnu-which'
  desc 'GNU which shows the full path of (shell) commands'
  homepage 'https://carlowood.github.io/which/index.html'
  url 'https://carlowood.github.io/which/which-${version}.tar.gz'

  release '2.21', crystax: 4

  build_copy 'COPYING'
  build_options copy_installed_dirs: ['bin'],
                gen_android_mk:      false

  def build_for_abi(abi, _toolchain, _release, _options)
    args =  [ "--disable-silent-rules" ]
    configure *args
    make
    make 'install'
  end
end
