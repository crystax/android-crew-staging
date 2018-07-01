class ProcpsNg < Package

  name 'procps-ng'
  desc 'Command line and full screen utilities for browsing procfs'
  homepage 'https://gitlab.com/procps-ng/procps'
  url "https://gitlab.com/procps-ng/procps.git|git_tag:v${version}"

  release '3.3.12', crystax: 6

  depends_on 'ncurses'

  build_copy 'COPYING'
  build_options copy_installed_dirs:  ['bin', 'include', 'lib', 'sbin'],
                gen_android_mk:       false

  def build_for_abi(abi, _toolchain, _release, _host_dep_dirs, target_dep_dirs, _options)
    install_dir = install_dir_for_abi(abi)
    ncurses_dir = target_dep_dirs['ncurses']

    # todo: remove HOST_NAME_MAX when libcrystax is fixed
    build_env['CFLAGS']  += " -I#{ncurses_dir}/include -I#{ncurses_dir}/include/ncursesw -DHOST_NAME_MAX=255 -D_GNU_SOURCE -D_DEFAULT_SOURCE"
    build_env['LDFLAGS'] += " -L#{ncurses_dir}/libs/#{abi}"
    build_env['LIBS']     = '-lncursesw'

    # these are needed to overwrite pkg-config found values
    build_env['NCURSES_CFLAGS']  = ' '
    build_env['NCURSES_LIBS']    = ' '
    build_env['NCURSESW_CFLAGS'] = ' '
    build_env['NCURSESW_LIBS']   = ' '

     if Global::OS == 'darwin'
       build_env['PATH'] = "/usr/local/opt/gettext/bin:#{ENV['PATH']}"
       fix_autogen_sh
    end

    args =  [ "--prefix=#{install_dir}",
              "--host=#{host_for_abi(abi)}",
              "--disable-silent-rules",
              "--disable-nls",
              "--disable-rpath",
	      "--with-pic",
	      "--enable-static",
	      "--disable-shared",
	      "--enable-watch8bit",
              "--enable-examples",
              "--with-sysroot"
            ]

    system './autogen.sh'
    set_ac_cv
    system './configure', *args
    unset_ac_cv
    system 'make', '-j', num_jobs
    system 'make', 'install'

    clean_install_dir abi, :lib
  end

  def fix_autogen_sh
    replace_lines_in_file('autogen.sh') do |line|
      case line
      when /libtoolize/
        line.gsub 'libtoolize', 'glibtoolize'
      when /libtool/
        line.gsub 'libtool', 'glibtool'
      else
        line
      end
    end
  end

  def set_ac_cv
    build_env['ac_cv_func_malloc_0_nonnull'] = 'yes'
    build_env['ac_cv_func_realloc_0_nonnull'] = 'yes'
  end

  def unset_ac_cv
    build_env.delete('ac_cv_func_malloc_0_nonnull')
    build_env.delete('ac_cv_func_realloc_0_nonnull')
  end
end
