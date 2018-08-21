class Ncurses < Package

  desc "The ncurses library is a free software emulation of curses in System V Release 4.0 (SVr4)"
  homepage "https://www.gnu.org/software/ncurses/"
  #url "https://github.com/mirror/ncurses/archive/v${version}.tar.gz"
  url "http://ftp.gnu.org/gnu/ncurses/ncurses-${version}.tar.gz"

  release '6.1'

  build_copy 'COPYING'
  build_options copy_installed_dirs:       ['bin', 'lib', 'include', 'share'],
                gen_android_mk:            false

  def build_for_abi(abi, _toolchain, release, _options)
    install_dir = install_dir_for_abi(abi)

    # todo: --with-pthread, --enable-reentrant, --disable-stripping?
    args = [ "--prefix=#{install_dir}",
             "--host=#{host_for_abi(abi)}",
             "--without-ada",
             "--without-cxx-binding",
             "--without-manpages",
             "--without-tests",
             #"--with-shared",
             "--without-termlib",
             "--without-dlsym",
             "--disable-rpath",
             "--disable-relink",
             "--disable-rpath-hack",
             "--enable-symlinks",
             "--enable-ext-colors",
             "--without-develop"
           ]

    # first, build without wide character support
    configure *(args << '--disable-widec')
    make
    make 'install'

    # second, build with wide character support
    configure *(args << '--enable-widec')
    make
    make 'install'

    clean_install_dir abi

    FileUtils.cd("#{install_dir}/lib") do
      suffix = ".#{release.major_point_minor}"
      Dir['*.so.*'].each do |f|
        FileUtils.mv f, File.basename(f, suffix)
      end
    end
  end

  def post_build(package_dir, _release)
    # fix link to terminfo
    # it should point two levels up (not one), since libs are put in separate dirs per abi
    FileUtils.cd("#{package_dir}/libs") do
      terminfo = 'terminfo'
      Arch::ABI_LIST.each do |abi|
        File.directory?(abi) and FileUtils.cd(abi) do
          if File.symlink? terminfo
            FileUtils.rm terminfo
            FileUtils.symlink '../../share/terminfo', terminfo
          end
        end
      end
    end
  end

  def sonames_translation_table(release)
    v = release.version.split('.')[0]
    { "libform.so.#{v}"     => 'libform',
      "libformw.so.#{v}"    => 'libformw',
      "libmenu.so.#{v}"     => 'libmenu',
      "libmenuw.so.#{v}"    => 'libmenuw',
      "libncurses.so.#{v}"  => 'libncurses',
      "libncursesw.so.#{v}" => 'libncursesw',
      "libnpanel.so.#{v}"   => 'libpanel',
      "libnpanelw.so.#{v}"  => 'libpanelw',
      "libtinfo.so.#{v}"    => 'libtinfo',
      "libtinfow.so.#{v}"   => 'libtinfow'
    }
  end

  def copy_to_deb_data_dir(package_dir, data_dir, abi, deb_type = :bin)
    super package_dir, data_dir, abi, deb_type

    # remove dangling symlink
    FileUtils.rm "#{data_dir}/usr/lib/terminfo"
  end
end
