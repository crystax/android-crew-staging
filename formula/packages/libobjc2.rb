class Libobjc2 < Package

  desc 'GNUstep Objective-C Runtime'
  homepage 'https://github.com/gnustep/libobjc2'
  url 'https://github.com/crystax/android-vendor-libobjc2.git|git_tag:$(version)_$(crystax_version)'

  release version: '1.8.1', crystax_version: 1, sha256: 'ecc54ab613cca8236eac12619356445140da65103fd2d74b5c0d5dd9508694f9'

  build_options setup_env: false

  def build_for_abi(abi, _toolchain, _release, _host_dep_dirs, target_dep_dirs)
    install_dir = install_dir_for_abi(abi)

    args = ["-DWITH_TESTS=NO",
	    "-DCMAKE_INSTALL_PREFIX=#{install_dir}",
	    "-DCMAKE_TOOLCHAIN_FILE=#{Build::CMAKE_TOOLCHAIN_FILE}",
	    "-DANDROID_ABI=#{abi}",
	    "-DANDROID_TOOLCHAIN_VERSION=clang#{Toolchain::DEFAULT_LLVM.version}",
	    "."
           ]

    system 'cmake', *args
    system 'make', '-j', num_jobs
    system 'make', 'install'

    internal_headers_dir = File.join(install_dir, 'include', 'internal')
    FileUtils.mkdir_p internal_headers_dir
    FileUtils.cp ['class.h', 'visibility.h'], internal_headers_dir
  end
end
