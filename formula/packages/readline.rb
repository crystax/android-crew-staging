class Readline < Package

  desc "The GNU Readline library provides a set of functions for use by applications that allow users to edit command lines as they are typed in"
  homepage "https://tiswww.case.edu/php/chet/readline/rltop.html"
  url "https://ftp.gnu.org/gnu/readline/readline-${version}.tar.gz"

  release version: '7.0', crystax_version: 2

  depends_on 'ncurses'

  build_copy 'COPYING'
  build_libs 'libhistory', 'libreadline'
  build_options sysroot_in_cflags: false

  def build_for_abi(abi, _toolchain,  release, _host_dep_dirs, target_dep_dirs, _options)
    install_dir = install_dir_for_abi(abi)
    ncurses_dir = target_dep_dirs['ncurses']

    build_env['CFLAGS']  += " -I#{ncurses_dir}/include"
    build_env['LDFLAGS'] += " -L#{ncurses_dir}/libs/#{abi}"
    build_env['LIBS']     = '-lncursesw'

    build_env['bash_cv_wcwidth_broken'] = 'no'

    args =  [ "--prefix=#{install_dir}",
              "--host=#{host_for_abi(abi)}",
              "--enable-multibyte",
              "--enable-shared",
              "--enable-static",
              "--with-curses"
            ]

    system './configure', *args
    system 'make', '-j', num_jobs
    system 'make', 'install'

    clean_install_dir abi, :lib

    FileUtils.cd("#{install_dir}/lib") do
      v = release.major_point_minor
      FileUtils.mv "libhistory.so.#{v}",  "libhistory.so"
      FileUtils.mv "libreadline.so.#{v}", "libreadline.so"
    end
  end

  def sonames_translation_table(release)
    v = release.version.split('.')[0]
    { "libhistory.so.#{v}"  => 'libhistory',
      "libreadline.so.#{v}" => 'libreadline'
    }
  end
end
