class Dpkg < Package

  desc "Debian's package maintenance system"
  homepage "https://wiki.debian.org/Teams/Dpkg"
  url "http://http.debian.net/debian/pool/main/d/dpkg/dpkg_${version}.tar.xz"

  release version: '1.19.0.5', crystax_version: 1

  depends_on 'libmd'
  depends_on 'xz'

  build_copy 'COPYING'
  build_options use_cxx: true,
                copy_installed_dirs: ['bin', 'etc', 'include', 'lib', 'share', 'var'],
                gen_android_mk: false

  def build_for_abi(abi, _toolchain,  _release, _host_dep_dirs, target_dep_dirs, _options)
    install_dir = install_dir_for_abi(abi)
    libmd_dir = target_dep_dirs['libmd']
    xz_dir = target_dep_dirs['xz']
    ncurses_dir = target_dep_dirs['ncurses']

    args =  [ "--prefix=#{install_dir}",
              "--host=#{host_for_abi(abi)}",
              "--disable-silent-rules",
              "--disable-nls",
              "--disable-rpath",
              "--enable-static",
              "--disable-dselect",
              "--disable-start-stop-daemon",
              "--disable-update-alternatives",
              "--with-pic",
              "--with-sysroot",
              "--with-libmd",
              "--with-libz",
              "--with-libbz2",
              "--with-liblzma"
            ]

    build_env['CPPFLAGS']  = "-I#{libmd_dir}/include -I#{xz_dir}/include -I#{ncurses_dir}/include"
    build_env['CPPFLAGS'] += " -USYNC_FILE_RANGE_WRITE" if abi == 'arm64-v8a'
    build_env['LDFLAGS']  += " -L#{libmd_dir}/libs/#{abi} -L#{xz_dir}/libs/#{abi} -L#{ncurses_dir}/libs/#{abi}"
    build_env['MD_LIBS']   = "-L#{libmd_dir}/libs/#{abi} -lmd"
    build_env['LZMA_LIBS'] = "-L#{xz_dir}/libs/#{abi} -llzma"



    build_env['ac_dpkg_arch'] = Deb.arch_for_abi(abi)

    system './configure', *args
    system 'make', '-j', num_jobs
    system 'make', 'install'

    clean_install_dir abi, :lib
    perl_dir = "#{install_dir}/share/perl5"
    FileUtils.mkdir_p "#{install_dir}/share/perl5"
    FileUtils.mv Dir["#{install_dir}/Dpkg*"], perl_dir
    FileUtils.rm_rf "#{install_dir}/share/man"
  end
end
