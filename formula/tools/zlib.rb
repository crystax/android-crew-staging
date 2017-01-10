class Zlib < BuildDependency

  desc 'A Massively Spiffy Yet Delicately Unobtrusive Compression Library'
  homepage 'http://zlib.net/'
  url 'http://zlib.net/zlib-${version}.tar.xz'

  release version: '1.2.10', crystax_version: 1, sha256: { linux_x86_64:   '145dc9f32d1a3a6d61b238b42833af3ac6717d1fca284874cdd77cae31c21495',
                                                           darwin_x86_64:  'f7cf92989369145ce0470472b142ecb276b3bc48c26ed5de3a0a1c3f8c98993d',
                                                           windows_x86_64: 'c4c71bbb0487bbe6fe2e18080ece5d7bab7ec998475d05ff30f363f270c830b9',
                                                           windows:        '2944b7add5ef08c9f5f06964b2938c0ad36c22fc7588f3e3b8200aa61cbcc626'
                                                         }

  def build_for_platform(platform, release, options, _host_dep_dirs, _target_dep_dirs)
    install_dir = install_dir_for_platform(platform, release)

    # copy sources; zlib doesn't support build in a separate directory
    FileUtils.cp_r File.join(src_dir, '.'), '.'

    if platform.target_os == 'windows'
      fname = 'win32/Makefile.gcc'
      text = File.read(fname).gsub(/^PREFIX/, '#PREFIX')
      File.open(fname, "w") {|f| f.puts text }

      # chop 'gcc' from the end of the string
      build_env['PREFIX'] = platform.cc.chop.chop.chop

      loc = platform.target_cpu == 'x86' ? 'LOC=-m32' : 'LOC=-m64'

      system 'make', '-j', num_jobs, loc, '-f', 'win32/Makefile.gcc', 'libz.a'

      FileUtils.mkdir_p ["#{install_dir}/lib", "#{install_dir}/include"]
      FileUtils.cp 'libz.a', "#{install_dir}/lib/"
      FileUtils.cp ['zlib.h', 'zconf.h'], "#{install_dir}/include/"
    else
      args = ["--prefix=#{install_dir}",
              "--static"
             ]

      system "#{src_dir}/configure", *args
      system 'make', '-j', num_jobs
      system 'make', 'check' if options.check? platform
      system 'make', 'install'

      FileUtils.rm_rf ["#{install_dir}/share", "#{install_dir}/lib/pkgconfig"]
    end
  end
end
