class Coreutils < Package

  desc "GNU File, Shell, and Text utilities"
  homepage "https://www.gnu.org/software/coreutils"
  url "https://ftpmirror.gnu.org/coreutils/coreutils-${version}.tar.xz"

  release '8.31', crystax: 3

  package_info root_dir: ['bin']

  build_copy 'COPYING'
  build_options copy_installed_dirs: ['bin', 'libexec'],
                gen_android_mk:      false


  def build_for_abi(abi, _toolchain,  _release, _options)
    args =  [ "--enable-single-binary=symlinks",
              "--disable-silent-rules",
              "--disable-rpath",
              "--disable-nls"
            ]

    configure *args
    add_soname_to_listbuf_so
    make
    make 'install'
  end

  def add_soname_to_listbuf_so
    replace_lines_in_file('Makefile') do |line|
      if line == 'src_libstdbuf_so_LDFLAGS = -shared'
        'src_libstdbuf_so_LDFLAGS = -shared -Wl,-soname,libstdbuf.so'
      else
        line
      end
    end
  end
end
