require_relative '../library/utils.rb'
require_relative '../library/build.rb'

class LibjpegTurbo < Library

  desc "JPEG image codec that aids compression and decompression"
  homepage "http://www.libjpeg-turbo.org/"
  url "https://downloads.sourceforge.net/project/libjpeg-turbo/{version}/libjpeg-turbo-{version}.tar.gz"

  release version: '1.4.2', crystax_version: 1, sha256: '0'

  def build(src_dir, arch_list)
    configure = Build::Configure.new(['--enable-shared', '--enable-static', '--with-pic', '--disable-ld-version-script'])
    configure.add_extra_args 'mips' => ['--without-simd']
    mk_modules = [ Build::AndroidMkModule.new('libturbojpeg'), Build::AndroidMkModule.new('libjpeg') ]
    #
    builder = Build::Builder.new(name, src_dir, configure, mk_modules)
    builder.libs_to_install = [ 'libturbojpeg.so', 'libturbojpeg.a', 'libjpeg.so', 'libjpeg.a' ]
    builder.prepare_package arch_list
  end
end
