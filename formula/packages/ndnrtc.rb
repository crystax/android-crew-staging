class Ndnrtc < Package

  desc "NDNRTC library"
  homepage "https://github.com/cawka/ndnrtc/"
  url 'https://github.com/cawka/ndnrtc|git_commit:941c9608799896d09fdf3c3ee7f12c548ef0e8d8'

  release version: '0.0.1', crystax_version: 2

  depends_on 'boost'
  depends_on 'ndn_cpp'
  depends_on 'openfec'
  depends_on 'webrtc'

  build_options setup_env:            false,
                use_cxx:              true,
                copy_installed_dirs:  [],
                gen_android_mk:       true

  def initialize(path)
    super path
    @lib_deps = Hash.new([])
  end

  def post_build(pkg_dir, release)
    gen_android_mk pkg_dir, release
    nil
  end

  def build_for_abi(abi, _toolchain, release, _host_dep_dirs, _target_dep_dirs, _options)

    @boost_dir = _target_dep_dirs['boost']
    @ndn_cpp_dir = _target_dep_dirs['ndn_cpp']
    @openfec_dir = _target_dep_dirs['openfec']
    @webrtc_dir = _target_dep_dirs['webrtc']

    arch = Build.arch_for_abi(abi)
    src_dir = build_dir_for_abi(abi)

    Build::TOOLCHAIN_LIST.each do |toolchain|
      Dir.chdir('cpp') do
        build_env.clear
        stl_name = toolchain.stl_name
        puts "    using C++ standard library: #{stl_name}"

        work_dir = "#{src_dir}/#{stl_name}"
        prefix_dir = "#{work_dir}/install"


        host_tc_dir = "#{work_dir}/host-bin"
        FileUtils.mkdir_p host_tc_dir
        host_cc = "#{host_tc_dir}/cc"
        Build.gen_host_compiler_wrapper host_cc, 'gcc'

        setup_build_env(abi, toolchain)

        File.open("VERSION", "w") do |f|
          f.write release.version
        end

        args = [ "--prefix=/",
                     "--enable-static=false",
                     "--host=#{host_for_abi(abi)}",
                     "--with-boost=#{@boost_dir}",
                     "--with-boost-libdir=#{@boost_dir}/libs/#{abi}/#{stl_name}",
                     "--sysconfdir=/etc",
                     "CFLAGS='-DWEBRTC_POSIX'",
                     "CXXFLAGS='-DWEBRTC_POSIX'",
                     "LDFLAGS='-Wl,-rpath-link,#{@boost_dir}/libs/#{abi}/#{stl_name} -lm -llog'",
                     "BOOSTDIR=#{@boost_dir}/include",
                     "BOOSTLIB=#{@boost_dir}/libs/#{abi}/#{stl_name}",
                     "NDNCPPDIR=#{@ndn_cpp_dir}/include",
                     "NDNCPPLIB=#{@ndn_cpp_dir}/libs/#{abi}/#{stl_name}",
                     "OPENFECSRC=#{@openfec_dir}/include",
                     "OPENFECLIB=#{@openfec_dir}/libs/#{abi}",
                     "WEBRTCDIR=#{@webrtc_dir}/include",
                     "WEBRTCLIB=#{@webrtc_dir}/libs/#{abi}"
                   ]

        puts "      configuring ndn-rtc"
        system "./configure", *args

        puts "      building ndn-rtc"
        system "make", "-j#{num_jobs}"
        system "make", "-j#{num_jobs}", "install", "DESTDIR=#{prefix_dir}"

        @lib_deps = Hash.new([])
        Dir["#{prefix_dir}/lib/*.so"].each do |lib|
          name = File.basename(lib).split('.')[0]
          abi_deps = toolchain.find_so_needs(lib, arch).select { |l| l.start_with? 'libboost_' }.map { |l| l.gsub(/^libboost_/, '') }.sort
          if @lib_deps[name] == []
            @lib_deps[name] = abi_deps
          elsif @lib_deps[name] != abi_deps
            raise "#{lib} has strange dependencies for #{arch.name} and #{toolchain.name}: expected: #{@lib_deps[name]}; got: #{abi_deps}"
          end
        end

        # copy headers if they were not copied yet
        inc_dir = "#{package_dir}/include"
        if !Dir.exists? inc_dir
          FileUtils.mkdir_p package_dir
          FileUtils.cp_r "#{prefix_dir}/include", package_dir
        end
        # copy libs
        libs_dir = "#{package_dir}/libs/#{abi}/#{stl_name}"
        FileUtils.mkdir_p libs_dir
        FileUtils.cp Dir["#{prefix_dir}/lib/*.so"], libs_dir
      end
    end
  end

  def gen_android_mk(pkg_dir, release)
    File.open("#{pkg_dir}/Android.mk", "w") do |f|
      f.puts Build::COPYRIGHT_STR
      f.puts ''
      f.puts 'LOCAL_PATH := $(call my-dir)'
      f.puts ''
      f.puts 'ifeq (,$(filter c++_%,$(APP_STL)))'
      f.puts '$(error $(strip \\'
      f.puts '    We do not support APP_STL \'$(APP_STL)\' for PSync! \\'
      f.puts '    Please use "c++_shared". \\'
      f.puts '))'
      f.puts 'endif'
      f.puts ''

      f.puts 'include $(CLEAR_VARS)'
      f.puts "LOCAL_MODULE := psync_shared"
      f.puts "LOCAL_SRC_FILES := libs/$(TARGET_ARCH_ABI)/llvm/libPSync.so"
      f.puts 'LOCAL_EXPORT_C_INCLUDES := $(LOCAL_PATH)/include/PSync'
      f.puts 'ifneq (,$(filter clang%,$(NDK_TOOLCHAIN_VERSION)))'
      f.puts 'LOCAL_EXPORT_LDLIBS := -latomic'
      f.puts 'endif'
      @lib_deps["libPSync"].each do |dep|
        f.puts "LOCAL_SHARED_LIBRARIES += boost_#{dep}_shared"
      end
      f.puts "LOCAL_SHARED_LIBRARIES += ndn_cpp_shared"
      f.puts 'include $(PREBUILT_SHARED_LIBRARY)'

      f.puts ''
      f.puts "$(call import-module,../packages/#{import_module_path(@boost_dir)})"
      f.puts "$(call import-module,../packages/#{import_module_path(@ndn_cpp_dir)})"

    end
  end

  # take two last components of the path
  def import_module_path(path)
    v = path.split('/')
    "#{v[v.size-2]}/#{v[v.size-1]}"
  end

  def sonames_translation_table(release)
    v = release.version.split('-')[0]
    puts "version for soname: #{v}"
    {
      "libwebrtc.so.#{v}" => "libwebrtc"
    }
  end

end
