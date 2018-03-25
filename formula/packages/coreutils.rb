class Coreutils < Package

  desc "GNU File, Shell, and Text utilities"
  homepage "https://www.gnu.org/software/coreutils"
  url "http://ftpmirror.gnu.org/coreutils/coreutils-${version}.tar.xz"

  release version: '8.29', crystax_version: 3

  build_copy 'COPYING'
  build_options copy_installed_dirs: ['bin', 'libexec'],
                gen_android_mk:      false


  SYMLINKS_SCRIPT = 'coreutils-create-symlinks.sh'

  def build_for_abi(abi, _toolchain,  _release, _host_dep_dirs, _target_dep_dirs, _options)
    install_dir = install_dir_for_abi(abi)

    build_env['PATH'] = Build.path

    args =  [ "--prefix=#{install_dir}",
              "--host=#{host_for_abi(abi)}",
              "--enable-single-binary=symlinks",
              "--disable-silent-rules",
              "--disable-rpath",
	      "--disable-nls"
            ]

    FileUtils.touch 'configure'

    system './configure', *args

    replace_lines_in_file('Makefile') do |line|
      if line == 'src_libstdbuf_so_LDFLAGS = -shared'
        'src_libstdbuf_so_LDFLAGS = -shared -Wl,-soname,libstdbuf.so'
      else
        line
      end
    end

    system 'make', '-j', num_jobs
    system 'make', 'install'

    FileUtils.cd("#{install_dir}/bin") do
      symlinks = Dir['*'] - ['coreutils']
      FileUtils.rm symlinks
      write_create_symlinks_script symlinks
    end
  end

  def write_create_symlinks_script(symlinks)
    File.open(SYMLINKS_SCRIPT, 'w') do |f|
      f.puts '#!/bin/sh'
      f.puts ''
      f.puts 'cd $(dirname $0)'
      f.puts ''
      f.puts "single_file_binaries=\"#{symlinks.join(' ')}\""
      f.puts ''
      f.puts 'for i in $single_file_binaries; do'
      f.puts 'ln -s coreutils $i;'
      f.puts 'done'
      f.puts ''
      f.puts 'cd -'
    end
    FileUtils.chmod '+x', SYMLINKS_SCRIPT
  end
end
