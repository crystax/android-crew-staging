class Ncurses < Package

  desc "The ncurses library is a free software emulation of curses in System V Release 4.0 (SVr4)"
  homepage "https://www.gnu.org/software/ncurses/"
  #url "http://ftp.gnu.org/gnu/ncurses/ncurses-${version}.tar.gz"
  url "https://github.com/mirror/ncurses/archive/v${version}.tar.gz"

  release version: '6.0', crystax_version: 1, sha256: 'f625b434865d126566b5492feea45e91a9199338cb7a42d087b31a0291074d2e'

  build_copy 'COPYING'
  build_options copy_installed_dirs: ['bin', 'lib', 'include', 'share'],
                gen_android_mk:      false

  def build_for_abi(abi, _toolchain, _release, _host_dep_dirs, _target_dep_dirs, _options)
    args = [ "--prefix=#{install_dir_for_abi(abi)}",
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

  def post_build(package_dir, _release)
    # fix link to terminfo
    # it should point two levels up (not one), since libs are put in separate dirs per abi
    FileUtils.cd("#{package_dir}/libs") do
      terminfo = 'terminfo'
      Build::ABI_LIST.each do |abi|
        File.directory?(abi) and FileUtils.cd(abi) do
          if File.symlink? terminfo
            FileUtils.rm terminfo
            FileUtils.symlink '../../share/terminfo', terminfo
          end
        end
      end
    end
  end
end
