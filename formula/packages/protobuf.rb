class Protobuf < Package

  desc "protobuf library"
  homepage "https://github.com/protocolbuffers/protobuf/"
  url 'https://github.com/protocolbuffers/protobuf.git|git_commit:6973c3a5041636c1d8dc5f7f6c8c1f3c15bc63d6'

  release version: '3.7.1', crystax_version: 1

  build_options setup_env:            false,
                use_cxx:              true,
                copy_installed_dirs:  [],
                gen_android_mk:       true

  def initialize(path)
    super path
    @lib_deps = Hash.new([])
  end

  # def pre_build(src_dir, release)
  # end

  def post_build(pkg_dir, release)
    gen_android_mk pkg_dir, release
    nil
  end

  def build_for_abi(abi, _toolchain, release, _host_dep_dirs, _target_dep_dirs, _options)
    
    args =  [
            ]

    arch = Build.arch_for_abi(abi)
    src_dir = build_dir_for_abi(abi)
    
    Build::TOOLCHAIN_LIST.each do |toolchain|
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

      cxx_args = [ "--prefix=/",
                   "--host=#{host_for_abi(abi)}",
                   "--enable-static=false",
                   "--with-protoc=/usr/local/bin/protoc", # hard-coded for now... adjust if different path
                 ]
      @build_env['LIBS'] = '-llog'

      system './autogen.sh'
      puts "      configuring"
      system "./configure", *args, *cxx_args

      puts "      building"
      system "make", "-j#{num_jobs}", "-v"
      system "make", "install", "DESTDIR=#{prefix_dir}"

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

  def gen_android_mk(pkg_dir, release)
    File.open("#{pkg_dir}/Android.mk", "w") do |f|
      f.puts Build::COPYRIGHT_STR
      f.puts ''
      f.puts 'LOCAL_PATH := $(call my-dir)'
      f.puts ''
      f.puts 'ifeq (,$(filter c++_%,$(APP_STL)))'
      f.puts '$(error $(strip \\'
      f.puts '    We do not support APP_STL \'$(APP_STL)\' for libprotobuf! \\'
      f.puts '    Please use "c++_shared". \\'
      f.puts '))'
      f.puts 'endif'
      f.puts ''

      f.puts 'include $(CLEAR_VARS)'
      f.puts "LOCAL_MODULE := protobuf_shared"
      f.puts "LOCAL_SRC_FILES := libs/$(TARGET_ARCH_ABI)/llvm/libprotobuf.so"
      f.puts 'LOCAL_EXPORT_C_INCLUDES := $(LOCAL_PATH)/include'
      f.puts 'ifneq (,$(filter clang%,$(NDK_TOOLCHAIN_VERSION)))'
      f.puts 'LOCAL_EXPORT_LDLIBS := -latomic -llog'
      f.puts 'endif'
      f.puts 'include $(PREBUILT_SHARED_LIBRARY)'

      f.puts ''
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
      "libprotobuf.so.#{v}" => "libprotobuf",
      "libprotobuf-lite.so.#{v}" => "libprotobuf-lite",
      "libprotoc.so.#{v}" => "libprotoc"      
    }
  end

end
