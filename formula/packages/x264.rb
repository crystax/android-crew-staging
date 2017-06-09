class X264 < Package

  desc "H.264/AVC encoder"
  homepage "https://www.videolan.org/developers/x264.html"
  url "https://git.videolan.org/git/x264.git|git_commit:90a61ec76424778c050524f682a33f115024be96"

  release version: 'r2762', crystax_version: 1, sha256: '0'

  build_copy 'COPYING'
  build_libs 'libx264'

  build_options sysroot_in_cflags:   false,
                copy_installed_dirs: ['bin', 'lib', 'include']

  def build_for_abi(abi, toolchain, _release, _host_dep_dirs, _target_dep_dirs, _options)
    install_dir = install_dir_for_abi(abi)
    args =  [ "--prefix=#{install_dir}",
              "--host=#{host_for_abi(abi)}",
              "--cross-prefix=#{host_for_abi(abi)}-",
              "--enable-shared",
              "--enable-static"
            ]

    args << '--disable-asm' if ['mips', 'mips64'].include? abi

    build_env['PATH'] = "#{toolchain.tc_prefix(Build.arch_for_abi(abi))}/bin:#{ENV['PATH']}"

    system './configure', *args
    system 'make', '-j', num_jobs, 'V=1'
    system 'make', 'install'

    # cleanup installation
    FileUtils.cd("#{install_dir}/lib") do
      FileUtils.rm_rf 'pkgconfig'
      FileUtils.rm 'libx264.so'
      FileUtils.mv Dir['libx264.so.*'][0], 'libx264.so'
    end
  end
end
