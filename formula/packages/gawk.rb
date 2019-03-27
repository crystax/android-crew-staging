class Gawk < Package

  desc "GNU awk utility"
  homepage "https://www.gnu.org/software/gawk/"
  url "https://ftp.gnu.org/gnu/gawk/gawk-${version}.tar.xz"

  release '4.2.1', crystax: 2

  depends_on 'readline'

  build_copy 'COPYING'
  build_options build_outside_source_tree: false,  # we need to copy sources because we change them
                copy_installed_dirs:       ['bin', 'etc', 'include', 'lib', 'libexec', 'share'],
                gen_android_mk:            false


  def build_for_abi(abi, toolchain,  _release, _options)
    args = [ '--disable-silent-rules',
             '--disable-nls',
             '--disable-rpath'
           ]

    fix_shell_prefix
    configure *args
    make
    make 'install'

    # remove unneeded files
    FileUtils.cd(install_dir_for_abi(abi)) do
      FileUtils.rm_r 'share/man'
      FileUtils.rm_r 'share/info'
    end
  end

  # todo: use some global constant or parameter or something else for shell prefix
  def fix_shell_prefix
    replace_lines_in_file('io.c') { |l| l.gsub('${CRYSTAX_SHELL_PREFIX}', '/system') }
  end
end
