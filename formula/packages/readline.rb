class Readline < Package

  desc "The GNU Readline library provides a set of functions for use by applications that allow users to edit command lines as they are typed in"
  homepage "https://tiswww.case.edu/php/chet/readline/rltop.html"
  url "https://ftp.gnu.org/gnu/readline/readline-${version}.tar.gz"

  release '8.0', crystax: 4

  depends_on 'ncurses'

  build_copy 'COPYING'
  build_libs 'libhistory', 'libreadline'
  build_options sysroot_in_cflags: false,
                add_deps_to_cflags: true,
                add_deps_to_ldflags: true

  def build_for_abi(abi, _toolchain,  release, _options)
    install_dir = install_dir_for_abi(abi)
    args =  [ "--enable-multibyte",
              "--enable-shared",
              "--enable-static",
              "--with-curses"
            ]

    build_env['bash_cv_wcwidth_broken'] = 'no'

    configure *args
    make
    make 'install'

    clean_install_dir abi

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
