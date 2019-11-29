class Zlib < Library

  desc 'A Massively Spiffy Yet Delicately Unobtrusive Compression Library'
  homepage 'http://zlib.net/'
  url 'http://zlib.net/zlib-${version}.tar.xz'
  url 'https://github.com/madler/zlib/archive/v${version}.tar.gz'

  release '1.2.11', crystax: 8

  postpone_install true

  def build_for_platform(platform, release, options)
    install_dir = install_dir_for_platform(platform.name, release)

    # copy sources; zlib doesn't support build in a separate directory
    FileUtils.cp_r File.join(src_dir, '.'), '.'

    if platform.target_os == 'windows'
      fname = 'win32/Makefile.gcc'
      text = File.read(fname).gsub(/^PREFIX/, '#PREFIX')
      text = text.gsub(/(RCFLAGS =)(.*)/, '\1' + '-F pe-i386' + '\2') if platform.target_cpu == 'x86'
      File.open(fname, "w") {|f| f.puts text }

      # chop 'gcc' from the end of the string
      build_env['PREFIX'] = platform.cc.chop.chop.chop

      loc = platform.target_cpu == 'x86' ? 'LOC=-m32' : 'LOC=-m64'

      targets = ['libz.a', 'zlib1.dll', 'libz.dll.a']
      system 'make', '-j', num_jobs, loc, '-f', 'win32/Makefile.gcc', *targets

      bin_dir = "#{install_dir}/bin"
      lib_dir = "#{install_dir}/lib"
      inc_dir = "#{install_dir}/include"

      FileUtils.mkdir_p [bin_dir, lib_dir, inc_dir]
      FileUtils.cp ['zlib1.dll'],            bin_dir
      FileUtils.cp ['libz.a', 'libz.dll.a'], lib_dir
      FileUtils.cp ['zlib.h', 'zconf.h'],    inc_dir
    else
      args = ["--prefix=#{install_dir}"]

      system "#{src_dir}/configure", *args
      system 'make', '-j', num_jobs
      system 'make', 'check' if options.check? platform
      system 'make', 'install'

      if platform.target_os == 'darwin'
        libname = "libz.#{release.version}.dylib"
        system 'install_name_tool', '-id', "@rpath/#{libname}", "#{install_dir}/lib/#{libname}"
      end
      FileUtils.rm_rf ["#{install_dir}/share", "#{install_dir}/lib/pkgconfig"]
    end
  end

  def split_file_list(list, platform_name)
    split_file_list_by_shared_libs(list, platform_name)
  end
end
