class Qrencode < Package

  desc "QR Code generation"
  homepage "https://fukuchi.org/works/qrencode/index.html.en"
  url "https://fukuchi.org/works/qrencode/qrencode-${version}.tar.gz"

  release version: '3.4.4', crystax_version: 1, sha256: '0'

  #depends_on 'libjpeg'

  build_copy 'COPYING'

  def build_for_abi(abi, _toolchain, release, _host_dep_dirs, _target_dep_dirs, _options)
    install_dir = install_dir_for_abi(abi)
    args =  [ "--prefix=#{install_dir}",
              "--host=#{host_for_abi(abi)}",
              "--enable-shared",
              "--enable-static",
              "--with-pic",
              "--without-tools"
            ]

    system './configure', *args
    system 'make', '-j', num_jobs, 'V=1'
    system 'make', 'install'

    # cleanup libs dir before packaging
    FileUtils.cd("#{install_dir}/lib") do
      FileUtils.rm_rf ['pkgconfig'] + Dir['*.la']
      FileUtils.rm ['libqrencode.so', "libqrencode.so.#{release.version.split('.')[0]}"]
      FileUtils.mv "libqrencode.so.#{release.version}", 'libqrencode.so'
    end
  end
end
