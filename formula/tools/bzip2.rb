# coding: utf-8
class Bzip2 < Library

  desc "bzip2 is a free and open-source file compression program that uses the Burrows–Wheeler algorithm. "
  homepage "https://sourceforge.net/projects/bzip2/"
  url "https://sourceforge.net/projects/bzip2/files/bzip2-1.0.6.tar.gz"

  release '1.0.6'

  def build_for_platform(platform, release, options)
    install_dir = install_dir_for_platform(platform.name, release)

    # copy sources; bzip2 doesn't support build in a separate directory
    FileUtils.cp_r File.join(src_dir, '.'), '.'

    build_env['CC'] = platform.cc
    build_env['AR'] = platform.ar
    build_env['RANLIB'] = platform.ranlib

    build_env['PLATFORM_CFLAGS']  = platform.cflags
    build_env['PLATFORM_CFLAGS'] += ' -DWIN32' if platform.target_os == 'windows'

    system 'make', '-j', num_jobs, 'libbz2.a', 'bzip2',  'bzip2recover'

    lib_dir = "#{install_dir}/lib"
    inc_dir = "#{install_dir}/include"

    FileUtils.mkdir_p [lib_dir, inc_dir]
    FileUtils.cp 'libbz2.a', lib_dir
    FileUtils.cp 'bzlib.h',  inc_dir
  end

  def split_file_list(list, platform_name)
    split_file_list_by_static_libs_and_includes(list, platform_name)
  end
end
