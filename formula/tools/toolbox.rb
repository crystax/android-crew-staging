class Toolbox < Utility

  desc "cmp and echo utilities for windows"
  homepage ''
  url ''

  release version: '1', crystax_version: 1, sha256: { linux_x86_64:   '0',
                                                      darwin_x86_64:  '0',
                                                      windows_x86_64: '0',
                                                      windows:        '0'
                                                    }

  executables 'cmp', 'echo'

  def prepare_source_code(release, dir, src_name, log_prefix)
    # source code is in source/host-tools/ directory
  end

  def build_for_platform(platform, release, options, _host_dep_dirs, _target_dep_dirs)
    if platform.target_os != 'windows'
      puts "#{name} can be build only for Windows OS"
      return
    end

    src_dir = File.join(Build::NDK_HOST_TOOLS_DIR, 'toolbox')
    bin_dir = File.join(install_dir_for_platform(platform, release), 'bin')
    FileUtils.mkdir_p bin_dir

    cc = platform.cc
    cflags = platform.cflags.split(' ')

    system cc, *cflags, "#{src_dir}/cmp_win.c",  '-o', "#{bin_dir}/cmd.exe"
    system cc, *cflags, "#{src_dir}/echo_win.c", '-o', "#{bin_dir}/echo.exe"
  end
end