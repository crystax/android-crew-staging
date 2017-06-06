class LibjpegTurbo < Package

  desc "JPEG image codec that aids compression and decompression"
  name 'libjpeg-turbo'
  homepage "http://www.libjpeg-turbo.org/"
  url "https://downloads.sourceforge.net/project/libjpeg-turbo/${version}/libjpeg-turbo-${version}.tar.gz"

  release version: '1.4.2', crystax_version: 1, sha256: '7780bec8ac2aba63fabd4d64219417c5b74ef8feac08ca794b4ba66cc98d1add'

  build_libs 'libturbojpeg', 'libjpeg'
  build_copy 'LICENSE.txt'
  build_options sysroot_in_cflags: false

  def build_for_abi(abi, _toolchain, _release, _host_dep_dirs, _target_dep_dirs)
    install_dir = install_dir_for_abi(abi)
    args =  [ "--prefix=#{install_dir_for_abi(abi)}",
              "--host=#{host_for_abi(abi)}",
              "--enable-shared",
              "--enable-static",
              "--with-pic",
              "--disable-ld-version-script"
            ]
    args << '--without-simd' if abi == 'mips'

    system './configure', *args
    system 'make', '-j', num_jobs, 'V=1'
    system 'make', 'install'

    # remove unneeded files
    FileUtils.rm Dir["#{install_dir}/lib/*.la"]
  end
end
