class Libpng < Package

  desc "Library for manipulating PNG images"
  homepage "http://www.libpng.org/pub/png/libpng.html"
  url "http://sourceforge.net/projects/libpng/files/libpng16/${version}/libpng-${version}.tar.xz"
  url "http://sourceforge.net/projects/libpng/files/libpng16/older-releases/${version}/libpng-${version}.tar.xz"

  release '1.6.29', crystax: 3

  build_copy 'LICENSE'
  build_options export_ldlibs: '-lz'

  def build_for_abi(abi, _toolchain, release, _host_dep_dirs, _target_dep_dirs, _options)
    install_dir = install_dir_for_abi(abi)
    args =  [ "--prefix=#{install_dir}",
              "--host=#{host_for_abi(abi)}",
              "--enable-shared",
              "--enable-static",
              "--disable-werror", # because of _POSIX_SOURCE redefinition
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
      vs = v2d(release)
      ['a', 'so'].each do |ext|
        FileUtils.rm "libpng.#{ext}"
        FileUtils.mv "libpng#{vs}.#{ext}", "libpng.#{ext}"
      end
    end
  end

  def sonames_translation_table(release)
    { "libpng#{v2d(release)}.so" => 'libpng' }
  end

  def v2d(release)
    release.version.split('.').first(2).join
  end
end
