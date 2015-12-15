require_relative '../library/utils.rb'
require_relative '../library/build.rb'

class Libpng < Library

  desc "Library for manipulating PNG images"
  homepage "http://www.libpng.org/pub/png/libpng.html"
  url "http://sourceforge.net/projects/libpng/files/libpng16/{version}/libpng-{version}.tar.xz"

  release version: '1.6.19', crystax_version: 1, sha256: '0'

  def build(src_dir, arch_list)
    configure = Build::Configure.new(['--enable-shared', '--enable-static', '--enable-werror', '--enable-unversioned-links', '--with-pic'])
    configure.add_extra_args 'armeabi-v7a' => ['--enable-arm-neon=api'], 'armeabi-v7a-hard' => ['--enable-arm-neon=api']
    mk_modules = [ Build::AndroidMkModule.new(name, export_ldlibs: "-lz") ]
    #
    builder = Build::Builder.new(name, src_dir, configure, mk_modules)
    builder.prepare_package arch_list
  end
end
