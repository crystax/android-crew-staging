class Zlib < BuildDependency

  desc 'A Massively Spiffy Yet Delicately Unobtrusive Compression Library'
  homepage 'http://zlib.net/'
  url 'http://zlib.net/zlib-${version}.tar.xz'
  url 'https://github.com/madler/zlib/archive/v${version}.tar.gz'

  release version: '1.2.11', crystax_version: 1, sha256: { linux_x86_64:   '539c09342078900c4e99a98f0eb2ddcb667295b19eb18fb4b121f260d7ed2d0c',
                                                           darwin_x86_64:  '7b12de1304d607b3320939c72f871463f84155b6e55208eb4b89c0816edfef77',
                                                           windows_x86_64: '81aedbf637367b6e044a1ea2248596fa173e86ab4e9449f8a1fbc3ffbef2b21f',
                                                           windows:        'ba5e83cb0fc1646cb0be6add96ab762bf02c77545980a5a7093ceb11786b23b2'
                                                         }

  def build_for_platform(platform, release, options, _host_dep_dirs, _target_dep_dirs)
    install_dir = install_dir_for_platform(platform.name, release)

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
