class Nawk < Utility

  desc "The One True Awk"
  homepage "https://www.cs.princeton.edu/~bwk/btl.mirror/"
  #url "https://www.cs.princeton.edu/~bwk/btl.mirror/awk.tar.gz"

  release version: '20071023', crystax_version: 1, sha256: { linux_x86_64:   'c21c911dc00d21435a6430afd546ab4061b8961a233270994a9d4a70247786de',
                                                             darwin_x86_64:  'e92361007eb3f47a4ada0767ef582d47ee67f024d5c7c4c7c248b5bbf55c1c8d',
                                                             windows_x86_64: '6eb77d48a7119900cc6483dc810965833049227f6b8cca656b3480621a2655d8',
                                                             windows:        '3bb79262ec1d92bc61d228fd9624fd85edb8ba26f955da6707b6e463185e2574'
                                                           }

  executables 'awk'

  def prepare_source_code(release, dir, src_name, log_prefix)
    # source code is in source/host-tools/ directory
  end

  def build_for_platform(platform, release, options, _host_dep_dirs, _target_dep_dirs)
    src_dir = File.join(Build::NDK_HOST_TOOLS_DIR, "nawk-#{release.version}")

    build_env['BUILD_DIR']     = Dir.pwd
    build_env['BUILD_MINGW']   = 'yes' if platform.target_os == 'windows'
    build_env['HOST_CC']       = platform.cc
    build_env['CFLAGS']       += ' -O2 -s'
    build_env['LDFLAGS']       = ' -m32' if platform.name == 'windows'
    build_env['NATIVE_CC']     = 'gcc'
    build_env['NATIVE_CFLAGS'] = " -O2 -s -I#{Dir.pwd} -I."
    build_env['V']             = '1'

    system 'make', '-j', num_jobs, '-C', src_dir

    bin_dir = File.join(install_dir_for_platform(platform, release), 'bin')
    FileUtils.mkdir_p bin_dir
    FileUtils.cp "ndk-awk", "#{bin_dir}/awk#{platform.target_exe_ext}"
  end
end
