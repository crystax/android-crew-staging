class Libjpeg < Library

  desc "JPEG image manipulation library"
  homepage "http://www.ijg.org"
  url "http://www.ijg.org/files/jpegsrc.v${version}.tar.gz"

  release version: '9a', crystax_version: 1, sha256: 'fbc9face5e1841b99bf5a89405c7d93315af9ea1f96c281c4b6660637b9a6037'

  build_copy 'README'

  def build_for_abi(abi, _toolchain, _release, _dep_dirs)
    args =  [ "--prefix=#{install_dir_for_abi(abi)}",
              "--host=#{host_for_abi(abi)}",
              "--enable-shared",
              "--enable-static",
              "--with-pic",
              "--disable-ld-version-script"
            ]

    build_env['CFLAGS'] << ' -mthumb' if abi =~ /^armeabi/

    system './configure', *args
    system 'make', '-j', num_jobs
    system 'make', 'install'
  end
end
