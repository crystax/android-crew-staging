class ProcpsNg < Package

  name 'procps-ng'
  desc 'Command line and full screen utilities for browsing procfs'
  homepage 'https://gitlab.com/procps-ng/procps'
  url "https://gitlab.com/procps-ng/procps.git|tag:v${version}"

  release '3.3.12', crystax: 7

  depends_on 'ncurses'

  build_copy 'COPYING'
  build_options build_outside_source_tree: false,
                add_deps_to_cflags:   false,
                add_deps_to_ldflags:  false,
                copy_installed_dirs:  ['bin', 'include', 'lib', 'sbin'],
                gen_android_mk:       false

  def build_for_abi(abi, _toolchain, release, _options)
    install_dir = install_dir_for_abi(abi)

    # todo: remove HOST_NAME_MAX when libcrystax is fixed
    inc_dir = target_dep_include_dir('ncurses')
    build_env['CFLAGS']  += " -I#{inc_dir} -I#{inc_dir}/ncursesw -DHOST_NAME_MAX=255 -D_GNU_SOURCE -D_DEFAULT_SOURCE"
    build_env['LDFLAGS'] += " -L#{target_dep_lib_dir('ncurses', abi)}"
    build_env['LIBS']     = '-lncursesw'

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
    configure *args
    unset_ac_cv
    make
    make 'install'

    clean_install_dir abi
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
