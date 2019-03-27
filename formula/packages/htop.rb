class Htop < Package

  desc 'htop is an interactive process viewer for Unix systems'
  homepage 'https://hisham.hm/htop/'
  url 'https://hisham.hm/htop/releases/${version}/htop-${version}.tar.gz'

  release '2.2.0', crystax: 4

  depends_on 'ncurses'

  build_copy 'COPYING'
  build_options add_deps_to_cflags:   true,
                add_deps_to_ldflags:  true,
                ldflags_in_c_wrapper: true,
                copy_installed_dirs:  ['bin'],
                gen_android_mk:       false,
                wrapper_remove_args:  ['-ltinfo'] # configure on linux adds it when testing for ncurses


  def build_for_abi(abi, _toolchain,  _release, _options)
    args =  [ "--disable-silent-rules",
	      "--enable-unicode",
              "--enable-linux-affinity"
            ]

    configure *args
    make
    make 'install'
  end
end
