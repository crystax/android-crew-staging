class ProcpsNg < Package

  name 'procps-ng'
  desc 'Command line and full screen utilities for browsing procfs'
  homepage 'https://gitlab.com/procps-ng/procps'
  url "https://gitlab.com/procps-ng/procps.git|git_tag:v${version}"

  release version: '3.3.12', crystax_version: 1

  depends_on 'ncurses'

  build_copy 'COPYING'
  build_options copy_installed_dirs: ['bin'],
                gen_android_mk:      false

  def build_for_abi(abi, _toolchain, _release, _host_dep_dirs, target_dep_dirs, _options)
    install_dir = install_dir_for_abi(abi)
    ncurses_dir = target_dep_dirs['ncurses']

    build_env['CFLAGS']  += " -I#{ncurses_dir}/include -L#{ncurses_dir}/libs/#{abi}"
    build_env['LIBS']     = '-ltinfow'

    args =  [ "--prefix=#{install_dir}",
              "--host=#{host_for_abi(abi)}",
              "--disable-silent-rules",
              "--disable-nls",
	      "--with-pic",
	      "--enable-static",
	      "--disable-shared",
	      "--enable-watch8bit",
	      "--disable-rpath"
            ]

    system './configure', *args
    system 'make', '-j', num_jobs
    system 'make', 'install'
  end
end
