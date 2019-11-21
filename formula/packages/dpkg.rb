class Dpkg < Package

  desc "Debian's package maintenance system"
  homepage "https://wiki.debian.org/Teams/Dpkg"
  url 'https://dl.crystax.net/mirror/dpkg-${version}.tar.xz'

  release '1.19.0.5', crystax: 9

  depends_on 'libmd'
  depends_on 'xz'

  build_copy 'COPYING'
  build_options use_cxx: true,
                copy_installed_dirs: ['bin', 'etc', 'include', 'lib', 'share', 'var'],
                gen_android_mk: false

  def build_for_abi(abi, _toolchain,  _release, _options)
    install_dir = install_dir_for_abi(abi)

    args =  [ "--disable-silent-rules",
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

    libmd_lib_dir = target_dep_lib_dir('libmd', abi)
    xz_lib_dir = target_dep_lib_dir('xz', abi)

    build_env['CPPFLAGS']  = "-I#{target_dep_include_dir('libmd')} -I#{target_dep_include_dir('xz')}"
    build_env['CPPFLAGS'] += " -USYNC_FILE_RANGE_WRITE" if abi == 'arm64-v8a'
    build_env['LDFLAGS']  += " -L#{libmd_lib_dir} -L#{xz_lib_dir}"
    build_env['MD_LIBS']   = "-L#{libmd_lib_dir} -lmd"
    build_env['LZMA_LIBS'] = "-L#{xz_lib_dir} -llzma"

    build_env['ac_dpkg_arch'] = Deb.arch_for_abi(abi)

    configure *args
    fix_tar_name if Global::OS == 'darwin'
    make
    make 'install'

    clean_install_dir abi
    perl_dir = "#{install_dir}/share/perl5"
    FileUtils.mkdir_p "#{install_dir}/share/perl5"
    FileUtils.mv Dir["#{install_dir}/Dpkg*"], perl_dir
    FileUtils.rm_rf "#{install_dir}/share/man"
  end

  def fix_tar_name
    replace_lines_in_file('config.h') do |line|
      line.sub(/^#define TAR "gtar"$/, '#define TAR "tar"')
    end
  end

  def copy_to_standalone_toolchain(release, arch, target_include_dir, target_lib_dir, options)
    super release, arch, target_include_dir, target_lib_dir, options

    FileUtils.cp_r "#{release_directory(release)}/share", "#{target_lib_dir}/../"
  end
end
