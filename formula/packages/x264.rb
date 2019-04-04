class X264 < Package

  desc "H.264/AVC encoder"
  homepage "https://www.videolan.org/developers/x264.html"
  url "https://git.videolan.org/git/x264.git|commit:72db437770fd1ce3961f624dd57a8e75ff65ae0b"

  release 'r2945'

  build_copy 'COPYING'
  build_libs 'libx264'

  build_options need_git_data: true,
                sysroot_in_cflags:   false,
                copy_installed_dirs: ['bin', 'lib', 'include']

  def build_for_abi(abi, toolchain, release, _options)
    install_dir = install_dir_for_abi(abi)

    args =  [ "--cross-prefix=#{host_for_abi(abi)}-",
              "--enable-shared",
              "--enable-static"
            ]

    args << '--disable-asm' if ['mips', 'mips64'].include? abi

    build_env['PATH'] = "#{toolchain.tc_prefix(Build.arch_for_abi(abi))}/bin:#{ENV['PATH']}"

    configure *args
    make
    make 'install'

    FileUtils.cd("#{install_dir}/lib") do
      FileUtils.rm 'libx264.so'
      FileUtils.mv Dir['libx264.so.*'][0], 'libx264.so'
    end
  end

  def sonames_translation_table(_release)
    { 'libx264.so.157' => 'libx264' }
  end

  def pc_edit_file(file, release, abi)
    super file, release, abi
    replace_lines_in_file(file) do |line|
      if line =~ /^Libs: /
        line.sub(/\${exec_prefix}\/lib/, '${libdir}')
      else
        line
      end
    end
  end
end
