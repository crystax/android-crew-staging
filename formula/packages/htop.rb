class Htop < Package

  desc 'htop is an interactive process viewer for Unix systems'
  homepage 'https://hisham.hm/htop/'
  url 'https://github.com/hishamhm/htop/archive/${version}.tar.gz'

  release '2.1.0', crystax: 3

  depends_on 'ncurses'

  build_copy 'COPYING'
  build_options copy_installed_dirs:  ['bin'],
                ldflags_in_c_wrapper: true,
                gen_android_mk:       false


  def build_for_abi(abi, _toolchain,  _release, _host_dep_dirs, target_dep_dirs, _options)
    install_dir = install_dir_for_abi(abi)
    ncurses_dir = target_dep_dirs['ncurses']

    build_env['CFLAGS']  += " -I#{ncurses_dir}/include -L#{ncurses_dir}/libs/#{abi}"
    build_env['LIBS']     = '-lncursesw'

    args =  [ "--prefix=#{install_dir}",
              "--host=#{host_for_abi(abi)}",
              "--disable-silent-rules",
	      "--enable-unicode",
              "--enable-linux-affinity"
            ]

    system './autogen.sh'
    system './configure', *args
    system 'make', '-j', num_jobs
    system 'make', 'install'
  end
end
