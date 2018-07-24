class X264 < Package

  desc "H.264/AVC encoder"
  homepage "https://www.videolan.org/developers/x264.html"
  url "https://git.videolan.org/git/x264.git|commit:7d0ff22e8c96de126be9d3de4952edd6d1b75a8c"

  release 'r2901'

  build_copy 'COPYING'
  build_libs 'libx264'

  build_options build_outside_source_tree: true,
                need_git_data: true,
                sysroot_in_cflags:   false,
                copy_installed_dirs: ['bin', 'lib', 'include']

  def build_for_abi(abi, toolchain, release, _host_dep_dirs, _target_dep_dirs, _options)
    install_dir = install_dir_for_abi(abi)
    src_dir = source_directory(release)

    args =  [ "--prefix=#{install_dir}",
              "--host=#{host_for_abi(abi)}",
              "--cross-prefix=#{host_for_abi(abi)}-",
              "--enable-shared",
              "--enable-static"
            ]

    args << '--disable-asm' if ['mips', 'mips64'].include? abi

    build_env['PATH'] = "#{toolchain.tc_prefix(Build.arch_for_abi(abi))}/bin:#{ENV['PATH']}"

    system "#{src_dir}/configure", *args
    system 'make', '-j', num_jobs, 'V=1'
    edit_pc_file 'x264.pc', release, abi

    system 'make', 'install'

    FileUtils.cd("#{install_dir}/lib") do
      FileUtils.rm 'libx264.so'
      FileUtils.mv Dir['libx264.so.*'][0], 'libx264.so'
    end
  end

  def sonames_translation_table(_release)
    { 'libx264.so.155' => 'libx264' }
  end

  def edit_pc_file(file, release, abi)
    replace_lines_in_file(file) do |line|
      case line
      when /^prefix=/
        "prefix=${ndk_dir}/packages/#{file_name}/#{release}"
      when /^exec_prefix=/
        nil
      when /^libdir=/
        "libdir=${prefix}/libs/#{abi}"
      when /^Libs: /
        line.sub(/\${exec_prefix}\/lib/, '${libdir}')
      else
        line
      end
    end
  end
end
