class Libpng < Package

  desc "Library for manipulating PNG images"
  homepage "http://www.libpng.org/pub/png/libpng.html"
  url "http://sourceforge.net/projects/libpng/files/libpng16/${version}/libpng-${version}.tar.xz"
  url "http://sourceforge.net/projects/libpng/files/libpng16/older-releases/${version}/libpng-${version}.tar.xz"

  release version: '1.6.21', crystax_version: 1, sha256: 'b45ba063b511e9dddfd3b11f848fc75bbb5f2e343afecb82c0863b53e4096ac4'

  build_copy 'LICENSE'
  build_options export_ldlibs: '-lz'

  def build_for_abi(abi, _toolchain, release, _host_dep_dirs, _target_dep_dirs)
    install_dir = install_dir_for_abi(abi)
    args =  [ "--prefix=#{install_dir}",
              "--host=#{host_for_abi(abi)}",
              "--enable-shared",
              "--enable-static",
              "--enable-werror",
              "--with-pic",
              "--enable-unversioned-links"
            ]
    args << '--enable-arm-neon=api' if abi == 'armeabi-v7a' or abi == 'armeabi-v7a-hard'

    system './configure', *args
    system 'make', '-j', num_jobs
    system 'make', 'install'

    # clean lib dir before packaging
    FileUtils.cd("#{install_dir}/lib") do
      FileUtils.rm_rf 'pkgconfig'
      FileUtils.rm Dir['*.la']
      vs = release.version.split('.').first(2).join
      ['a', 'so'].each do |ext|
        FileUtils.rm "libpng.#{ext}"
        FileUtils.mv "libpng#{vs}.#{ext}", "libpng.#{ext}"
      end
    end
  end
end
