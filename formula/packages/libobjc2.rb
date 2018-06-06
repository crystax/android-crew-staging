class Libobjc2 < Package

  desc 'GNUstep Objective-C Runtime'
  homepage 'https://github.com/gnustep/libobjc2'
  # todo: use commit? tag? something else?
  url 'https://github.com/crystax/android-vendor-libobjc2.git|git_commit:36d73233f25183d7f371176e0417ca1c94c43c6f'

  release version: '1.8.1', crystax_version: 3

  build_options setup_env: false

  def build_for_abi(abi, _toolchain, _release, _host_dep_dirs, target_dep_dirs, _options)
    install_dir = install_dir_for_abi(abi)

    args = ["-DWITH_TESTS=NO",
	    "-DCMAKE_INSTALL_PREFIX=#{install_dir}",
	    "-DCMAKE_TOOLCHAIN_FILE=#{Build::CMAKE_TOOLCHAIN_FILE}",
            "-DCMAKE_MAKE_PROGRAM=make",
	    "-DANDROID_ABI=#{abi}",
	    "-DANDROID_TOOLCHAIN_VERSION=clang#{Toolchain::DEFAULT_LLVM.version}",
	    "."
           ]

    # cmake (on linux) is built with curl
    # this should prevent system cmake using our libcurl or any other libs from prebuilt/*/lib
    build_env['LD_LIBRARY_PATH'] = nil

    system 'cmake', *args
    system 'make', '-j', num_jobs
    system 'make', 'install'

    internal_headers_dir = File.join(install_dir, 'include', 'internal')
    FileUtils.mkdir_p internal_headers_dir
    FileUtils.cp ['class.h', 'visibility.h'], internal_headers_dir
  end
end
