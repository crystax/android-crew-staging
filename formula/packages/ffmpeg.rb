class Ffmpeg < Package

  desc "A complete, cross-platform solution to record, convert and stream audio and video"
  homepage "https://www.ffmpeg.org"
  url "https://ffmpeg.org/releases/ffmpeg-${version}.tar.bz2"

  release '4.0.2'
  #release '4.1'

  depends_on 'xz'
  depends_on 'x264'
  depends_on 'gmp'
  depends_on 'gnu-tls'

  build_copy 'LICENSE.md', 'COPYING.GPLv2', 'COPYING.GPLv3', 'COPYING.LGPLv2.1', 'COPYING.LGPLv3'
  build_libs 'libavcodec', 'libavdevice', 'libavfilter', 'libavformat', 'libavutil', 'libpostproc', 'libswresample', 'libswscale'

  build_options use_standalone_toolchain: true,
                ldflags_no_pie: true,
                use_cxx: true,
                copy_installed_dirs: ['bin', 'include', 'lib', 'share']

  def build_for_abi(abi, toolchain, release, _options)
    install_dir = install_dir_for_abi(abi)

    arch, cpu = target_arch_and_cpu_for_abi(abi)
    pkg_config = Global::OS == 'darwin' ? '/usr/local/bin/pkg-config' : '/usr/bin/pkg-config'

    args =  [ "--prefix=#{install_dir}",
	      "--enable-cross-compile",
              "--arch=#{arch}",
	      "--cpu=#{cpu}",
              "--target-os=android",
              "--cross-prefix=#{host_for_abi(abi)}-",
	      "--enable-pic",
	      "--disable-doc",
	      "--disable-symver",
	      "--disable-yasm",
	      "--enable-static",
	      "--enable-shared",
	      "--enable-gpl",
              "--enable-version3",
              "--enable-gmp",
	      "--enable-libx264",
              "--enable-gnutls",
              "--enable-cross-compile",
              "--cc=#{build_env['CC']}",
              "--cxx=#{build_env['CXX']}",
              "--pkg-config=#{pkg_config}",
              "--extra-ldexeflags=-pie"
            ]

    gnutls_libs = '-lgnutls -lp11-kit -lidn2 -lunistring -lnettle -lhogweed -lffi -lgmp -lz'

    build_env['LDFLAGS'] += ' ' + gnutls_libs + ' -lx264 -lgmp -llzma' + " -L#{toolchain.sysroot_dir}/usr/lib64"
    build_env['PATH'] = "#{toolchain.bin_dir}:#{Build.path}"

    system "#{source_directory(release)}/configure", *args
    # add_pie_to_exe_ldflags
    make 'V=1'
    make 'install'

    # cleanup installation
    # FileUtils.cd("#{install_dir}/lib") do
    #   FileUtils.rm_rf 'pkgconfig'
    #   FileUtils.rm 'libx264.so'
    #   FileUtils.mv Dir['libx264.so.*'][0], 'libx264.so'
    # end
  end

  def target_arch_and_cpu_for_abi(abi)
    case abi
    when /^armeabi-v7a/
      ['arm', 'armv7-a']
    when 'arm64-v8a'
      ['aarch64', 'armv8-a']
    when 'mips'
      ['mipsel', 'mips32r6']
    when 'x86'
      ['x86', 'atom']
    when 'x86_64'
      ['x86_64', 'atom']
    when 'mips64'
      ['mips64', 'mips64r6']
    else
      raise "unsupported abi '#{abi}'"
    end
  end

  # def add_pie_to_exe_ldflags
  #   replace_lines_in_file('ffbuild/config.mak') do |line|
  #     if line =~ /^LDEXEFLAGS=/
  #       line.sub(/^LDEXEFLAGS=/, 'LDEXEFLAGS=-pie ')
  #     else
  #       line
  #     end
  # end

  # def sonames_translation_table(_release)
  #   { 'libx264.so.148' => 'libx264' }
  # end
end
