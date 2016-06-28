class Ncurses < Package

  desc "The ncurses library is a free software emulation of curses in System V Release 4.0 (SVr4)"
  homepage "https://www.gnu.org/software/ncurses/"
  url "http://ftp.gnu.org/gnu/ncurses/ncurses-${version}.tar.gz"

  release version: '6.0', crystax_version: 1, sha256: '0'

  build_copy 'COPYING'
  build_options copy_installed_dirs: ['bin', 'lib', 'include', 'share'],
                gen_android_mk:      false

  def build_for_abi(abi, _toolchain, _release, _dep_dirs)
    args =  [ "--prefix=#{install_dir_for_abi(abi)}",
              "--host=#{host_for_abi(abi)}",
              "--without-ada",
              "--without-cxx-binding",
              "--without-manpages",
              "--without-tests",
              "--without-dlsym",
              "--with-termlib",
              "--enable-symlinks",
              "--enable-ext-colors",
              "--without-develop"
            ]

    # build fails (at least on darwin) if configure run without full path
    configure = Pathname.new('./configure').realpath.to_s

    # first, build without wide character support
    system configure, *(args << '--disable-widec')
    system 'make', '-j', num_jobs
    system 'make', 'install'

    # second, build with wide character support
    system configure, *(args << '--enable-widec')
    system 'make', '-j', num_jobs
    system 'make', 'install'
  end
end
