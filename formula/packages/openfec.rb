class Openfec < Package

  desc 'OpenFEC library'
  homepage 'http://openfec.org'
  url 'http://openfec.org/files/openfec_v${version}.tgz' do |r| r.version.gsub('.', '_') end

  release version: '1.4.2', crystax_version: 1

  build_options setup_env: false

  def build_for_abi(abi, _toolchain, _release, _host_dep_dirs, target_dep_dirs, _options)
    install_dir = install_dir_for_abi(abi)

    args = ["-DWITH_TESTS=NO",
	    "-DCMAKE_INSTALL_PREFIX=#{install_dir}",
	    "-DCMAKE_TOOLCHAIN_FILE=#{Build::CMAKE_TOOLCHAIN_FILE}",
            "-DCMAKE_MAKE_PROGRAM=make",
	    "-DANDROID_ABI=#{abi}",
            "-DANDROID_COMPILER_FLAGS_RELEASE='-DANDROID=1'",
	    "."
           ]

    # cmake (on linux) is built with curl
    # this should prevent system cmake using our libcurl or any other libs from prebuilt/*/lib
    build_env['LD_LIBRARY_PATH'] = nil

    system 'cmake', *args
    system 'make', 'VERBOSE=1', '-j', num_jobs
    
    bin_dir = File.join(install_dir, 'lib')
    FileUtils.mkdir_p bin_dir
    FileUtils.cp 'bin/Release/libopenfec.so', bin_dir

    headers_dir = File.join(install_dir, 'include')

    Dir.chdir('src') do
      stack = ['lib_advanced', 'lib_common', 'lib_stable']
      while stack.size() > 0
        dirStr = stack.pop()
        dir = File.join(headers_dir, dirStr)
        FileUtils.mkdir_p dir
        FileUtils.cp_r Dir.glob("#{dirStr}/*.h"), dir

        Dir.glob("#{dirStr}/*").each do |d|
          stack.push(d) if File.directory?(d)
        end
      end
    end
  end
end
