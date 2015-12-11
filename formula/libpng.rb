require_relative '../library/utils.rb'
require_relative '../library/build.rb'

class Libpng < Library

  desc "Library for manipulating PNG images"
  homepage "http://www.libpng.org/pub/png/libpng.html"

  release version: '1.6.19', crystax_version: 1, sha256: '6b390ea6655ee5b62ca04d92b01098b90155970a4241a40addfa156d62f660f3'

  def install_source_code(release, dirname)
    ver = release.version
    url = "http://sourceforge.net/projects/libpng/files/libpng16/#{ver}/libpng-#{ver}.tar.xz"
    std_download_source_code url, release_directory(release), "#{name}-#{ver}", dirname
  end

  def build(src_dir, arch_list)
    configure = Build::Configure.new(['--enable-shared', '--enable-static', '--enable-werror', '--enable-unversioned-links', '--with-pic'])
    #configure.autogen_script = './autogen.sh'
    configure.add_extra_args 'armeabi-v7a' => ['--enable-arm-neon=api'], 'armeabi-v7a-hard' => ['--enable-arm-neon=api']
    mk_modules = [ Build::AndroidMkModule.new(name, export_ldlibs: "-lz") ]
    #
    builder = Build::Builder.new(name, src_dir, configure, mk_modules)
    builder.prepare_package arch_list
  end
end
