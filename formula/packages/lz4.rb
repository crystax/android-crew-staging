class Lz4 < Package

  desc "LZ4 is lossless compression algorithm, providing compression speed at 400 MB/s per core"
  homepage "http://lz4.github.io/lz4/"
  url "https://github.com/lz4/lz4/archive/v${version}.tar.gz"

  release version: '1.8.1.2', crystax_version: 1

  build_copy 'LICENSE'
  build_options copy_installed_dirs: ['bin', 'include', 'lib']

  def build_for_abi(abi, _toolchain,  release, _host_dep_dirs, _target_dep_dirs, _options)
    install_dir = install_dir_for_abi(abi)

    # args =  [ "--prefix=#{install_dir}",
    #           "--host=#{host_for_abi(abi)}",
    #           "--disable-silent-rules",
    #           "--disable-nls",
    #           "--disable-doc",
    #           "--disable-lzma-links",
    #           "--enable-shared",
    #           "--enable-static",
    #           "--with-pic",
    #           "--with-sysroot"
    #         ]

    system 'make', '-j', num_jobs
    system 'make', "prefix=#{install_dir}", 'install'

    clean_install_dir abi, :lib
    FileUtils.cd("#{install_dir}/lib") do
      v = release.version.split('.').first(3).join('.')
      FileUtils.mv "liblz4.so.#{v}", "liblz4.so"
    end
  end

  def sonames_translation_table(release)
    v = release.version.split('.')[0]
    { "liblz4.so.#{v}" => 'liblz4' }
  end
end
