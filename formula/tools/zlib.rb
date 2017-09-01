class Zlib < BuildDependency

  desc 'A Massively Spiffy Yet Delicately Unobtrusive Compression Library'
  homepage 'http://zlib.net/'
  url 'http://zlib.net/zlib-${version}.tar.xz'
  url 'https://github.com/madler/zlib/archive/v${version}.tar.gz'

  release version: '1.2.11', crystax_version: 2

  def build_for_platform(platform, release, options, _host_dep_dirs, _target_dep_dirs)
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

      #system 'make', '-j', num_jobs, loc, '-f', 'win32/Makefile.gcc', 'libz.a'

      targets = ['libz.a', 'zlib1.dll', 'libz.dll.a']
      system 'make', '-j', num_jobs, loc, '-f', 'win32/Makefile.gcc', *targets

      FileUtils.mkdir_p ["#{install_dir}/lib", "#{install_dir}/include"]
      FileUtils.cp targets, "#{install_dir}/lib/"
      FileUtils.cp ['zlib.h', 'zconf.h'], "#{install_dir}/include/"
    else
      # args = ["--prefix=#{install_dir}",
      #         "--static"
      #        ]
      args = ["--prefix=#{install_dir}"]

      system "#{src_dir}/configure", *args
      system 'make', '-j', num_jobs
      system 'make', 'check' if options.check? platform
      system 'make', 'install'

      FileUtils.rm_rf ["#{install_dir}/share", "#{install_dir}/lib/pkgconfig"]
    end
  end
end
