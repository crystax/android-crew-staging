require_relative '../library/utils.rb'
require_relative '../library/build.rb'

class Libjpeg < Library

  desc "JPEG image manipulation library"
  homepage "http://www.ijg.org"

  release version: '9a', crystax_version: 1, sha256: '6b390ea6655ee5b62ca04d92b01098b90155970a4241a40addfa156d62f660f3'

  def install_source_code(release, dirname)
    ver = release.version
    url = "http://www.ijg.org/files/jpegsrc.v#{ver}.tar.gz"
    std_download_source_code url, release_directory(release), "jpeg-#{ver}", dirname
  end

  def build(src_dir, arch_list)
    conf_args = ["--enable-shared", "--enable-static", "--with-pic", "--disable-ld-version-script"]
    mk_modules = [ Build::AndroidMkModule.new(name) ]
    #
    builder = Build::Builder.new(name, src_dir, conf_args, mk_modules)
    builder.prepare_package arch_list
  end
end
