class Nawk < Utility

  desc "The One True Awk"
  homepage "https://www.cs.princeton.edu/~bwk/btl.mirror/"
  #url "https://www.cs.princeton.edu/~bwk/btl.mirror/awk.tar.gz"

  release version: '20071023', crystax_version: 1, sha256: { linux_x86_64:   'b7e4fea021225c7bc628cbdb304f6e7630ce6faddbeda2a4faec46a932de37d9',
                                                             darwin_x86_64:  '970141e24e1a1bddb4c0e1f6537f7493b0bf09f106ebe3ccb841aefe5a19d3ef',
                                                             windows_x86_64: '49eabdfae5b5af478a1dd799dd17ac3ae85e0c092fa7b44594ab35e3f09b3578',
                                                             windows:        '82511ab010e24ee06a23da66dca5df70546c2e2142f082401381f704b0d479a4'
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
