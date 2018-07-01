class Nawk < Utility

  desc "The One True Awk"
  homepage "https://www.cs.princeton.edu/~bwk/btl.mirror/"
  #url "https://www.cs.princeton.edu/~bwk/btl.mirror/awk.tar.gz"

  release '20071023', crystax: 3

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

    bin_dir = File.join(install_dir_for_platform(platform.name, release), 'bin')
    FileUtils.mkdir_p bin_dir
    FileUtils.cp "ndk-awk", "#{bin_dir}/awk#{platform.target_exe_ext}"
  end
end
