class Boost < Library

  desc "Boost libraries built without ICU4C"
  homepage "http://www.boost.org"
  url "https://downloads.sourceforge.net/project/boost/boost/${version}/boost_${block}.tar.bz2" do |v| v.gsub('.', '_') end

  release version: '1.60.0', crystax_version: 1, sha256: '0'

  patch :DATA
  build_options setup_env: false,
                copy_incs_and_libs: false,
                wrapper_replace: { '-dynamiclib'    => '-shared',
                                   '-undefined'     => '-u',
                                   '-m32'           => '',
                                   '-m64'           => '',
                                   '-single_module' => '',
                                   '-lpthread'      => '',
                                   '-lutil'         => ''
                                 }
  build_libs 'atomic',
             'chrono',
             'container',
             'context',
             'coroutine',
             'date_time',
             'exception',
             'filesystem',
             'graph',
             'iostreams',
             'locale',
             'log',
             'log_setup',
             'math_c99',
             'math_c99f',
             'math_c99l',
             'math_tr1',
             'math_tr1f',
             'math_tr1l',
             'prg_exec_monitor',
             'program_options',
             'python',
             'python3',
             'random',
             'regex',
             'serialization',
             'signals',
             'system',
             'test_exec_monitor',
             'thread',
             'timer',
             'type_erasure',
             'unit_test_framework',
             'wave',
             'wserialization'

  def initialize(path)
    super path
    @lib_deps = Hash.new([])
  end

  def pre_build(src_dir, release)
    # todo: build bjam here
  end

  def post_build(pkg_dir, release)
    gen_android_mk pkg_dir, release
  end

  def build_for_abi(abi, toolchain, release, _dep_dirs)
    args =  [ "--prefix=#{install_dir_for_abi(abi)}",
              "--host=#{host_for_abi(abi)}",
              "--enable-shared",
              "--enable-static",
              "--with-pic",
              "--disable-ld-version-script"
            ]

    arch = Build.arch_for_abi(abi)
    bjam_arch, bjam_abi = bjam_data(arch)

    common_args = [ "-d+2",
                    "-q",
                    "-j#{num_jobs}",
                    "variant=release",
                    "link=static,shared",
                    "runtime-link=shared",
                    "threading=multi",
                    "target-os=android",
                    "binary-format=elf",
                    "address-model=#{arch.num_bits}",
                    "architecture=#{bjam_arch}",
                    "abi=#{bjam_abi}",
                    "--user-config=user-config.jam",
                    "--layout=system",
                    without_libs(release, arch).map { |lib| "--without-#{lib}" },
             "install"
           ].flatten

    #[Toolchain::GCC_4_9].each do |toolchain|
    #[Toolchain::LLVM_3_6].each do |toolchain|
    Build::TOOLCHAIN_LIST.each do |toolchain|
      stl_name = toolchain.stl_name
      puts "    using C++ standard library: #{stl_name}"
      # todo: copy sources for every toolchain
      src_dir = build_dir_for_abi(abi)
      work_dir = "#{src_dir}/#{stl_name}"
      host_tc_dir = "#{work_dir}/host-bin"
      FileUtils.mkdir_p host_tc_dir
      host_cc = "#{host_tc_dir}/cc"
      Build.gen_host_compiler_wrapper host_cc, 'gcc'

      build_env['PATH'] = "#{work_dir}:#{ENV['PATH']}"
      system './bootstrap.sh',  "--with-toolset=cc"

      gen_project_config_jam src_dir, arch, abi, stl_name
      gen_user_config_jam    src_dir

      build_env.clear
      cxx = "#{build_dir_for_abi(abi)}/#{toolchain.cxx_compiler_name}"
      cxxflags = toolchain.cflags(abi) + ' ' +
                 Build.sysroot(abi) + ' ' +
                 toolchain.search_path_for_stl_includes(abi) + ' ' +
                 '-fPIC -Wno-long-long'

      ldflags  = { before: toolchain.ldflags(abi) + ' ' +
                           Build.sysroot(abi) + ' ' +
                           toolchain.search_path_for_stl_libs(abi),
                   after:  "-l#{toolchain.stl_lib_name}_shared"
                 }

      Build.gen_compiler_wrapper cxx, toolchain.cxx_compiler(arch, abi), toolchain, build_options, cxxflags, ldflags
      #['as', 'ar', 'ranlib', 'strip'].each { |tool| Build.gen_tool_wrapper build_dir_for_abi(abi), tool, toolchain, arch }

      build_env['PATH'] = "#{src_dir}:#{ENV['PATH']}"

      build_dir = "#{work_dir}/build"
      prefix_dir = "#{work_dir}/install"
      args = common_args + ["--prefix=#{prefix_dir}", "--build-dir=#{build_dir}"]

      system './b2', *args

      # find and store dependencies for the built libraries
      Dir["#{prefix_dir}/lib/*.so"].each do |lib|
        name = File.basename(lib).split('.')[0].sub('libboost_', '')
        abi_deps = toolchain.find_so_needs(lib, arch).select { |l| l.start_with? 'libboost_' }.map { |l| l.split('_')[1].split('.')[0] }.sort
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
      FileUtils.cp Dir["#{prefix_dir}/lib/*.a"],  libs_dir
      FileUtils.cp Dir["#{prefix_dir}/lib/*.so"], libs_dir
    end
  end

  def bjam_data(arch)
    case arch.name
    when /^arm/               # arm|arm64
      bjam_arch = 'arm'
      bjam_abi = 'aapcs'
    when /^x86/               # x86|x86_64
      bjam_arch = 'x86'
      bjam_abi  = 'sysv'
    when 'mips'
      bjam_arch = 'mips1'
      bjam_abi  = 'o32'
    when 'mips64'
      bjam_arch = 'mips1'
      bjam_abi  = 'o64'
    else
      raise UnsupportedArch.new(arch)
    end

    [bjam_arch, bjam_abi]
  end

  def without_libs(release, arch)
    exclude_libs(release).select { |_, v| v.include? arch.name }.keys
  end

  def exclude_libs(release)
    exclude = {}
    major, minor, _ = release.version.split('.').map { |a| a.to_i }

    # Boost.Context in 1.60.0 and earlier don't support mips64
    if major == 1 and minor <= 60
      exclude['context']   = ['mips64']
    end

    # Boost.Coroutine depends on Boost.Context
    if archs = exclude['context']
      exclude['coroutine'] = archs
      # Starting from 1.59.0, there is Boost.Coroutine2 library, which depends on Boost.Context too
      if major == 1 and minor >= 59
        exclude['coroutine2'] = archs
      end
    end

    exclude
  end

  def gen_project_config_jam(dir, arch, abi, stl_name)
    # todo: handle python
    python_version = '3.5'
    python_dir = "#{Global::NDK_DIR}/sources/python/#{python_version}"

    File.open("#{dir}/project-config.jam", 'w') do |f|
      f.puts "import option ;"
      f.puts "import feature ;"
      f.puts "import python ;"
      f.puts "using python : #{python_version} : #{python_dir} : #{python_dir}/include/python : #{python_dir}/libs/#{abi} ;"
      case stl_name
      when /^gnu-/
        f.puts "using gcc : #{arch.name} : g++ ;"
        f.puts "project : default-build <toolset>gcc ;"
      when /^llvm-/
        f.puts "using clang : #{arch.name} : clang++ ;"
        f.puts "project : default-build <toolset>clang ;"
      else
        raise "unsupported C++ standard library: #{stl_name}"
      end
      f.puts "libraries = ;"
      f.puts "option.set keep-going : false ;"
    end
  end

  def gen_user_config_jam(dir)
    File.open("#{dir}/user-config.jam", 'w') { |f| f.puts "using mpi ;" }
  end

  def gen_android_mk(pkg_dir, release)
    exclude = exclude_libs(release)

    File.open("#{pkg_dir}/Android.mk", "w") do |f|
      f.puts Build::COPYRIGHT_STR
      f.puts ''
      f.puts 'LOCAL_PATH := $(call my-dir)'
      f.puts ''
      f.puts 'ifeq (,$(filter gnustl_% c++_%,$(APP_STL)))'
      f.puts '$(error $(strip \\'
      f.puts '    We do not support APP_STL \'$(APP_STL)\' for Boost libraries! \\'
      f.puts '    Please use either "gnustl_shared", "gnustl_static", "c++_shared" or "c++_static". \\'
      f.puts '))'
      f.puts 'endif'
      f.puts ''
      f.puts '__boost_libstdcxx_subdir := $(strip \\'
      f.puts '    $(strip $(if $(filter c++_%,$(APP_STL)),\\'
      f.puts '        llvm,\\'
      f.puts '        gnu\\'
      f.puts '    ))-$(strip $(if $(filter c++_%,$(APP_STL)),\\'
      f.puts '        $(if $(filter clang%,$(NDK_TOOLCHAIN_VERSION)),$(patsubst clang%,%,$(NDK_TOOLCHAIN_VERSION)),$(DEFAULT_LLVM_VERSION)),\\'
      f.puts '        $(if $(filter clang%,$(NDK_TOOLCHAIN_VERSION)),$(DEFAULT_GCC_VERSION),$(or $(NDK_TOOLCHAIN_VERSION),$(DEFAULT_GCC_VERSION)))\\'
      f.puts '    ))\\'
      f.puts ')'
      f.puts ''
      build_libs.each do |name|
        exclude_flag = false
        if archs = exclude[name]
          exclude_flag = true
          f.puts "ifeq (,$(filter #{archs.join(' ')},$(TARGET_ARCH_ABI)))"
        end
        f.puts 'include $(CLEAR_VARS)'
        f.puts "LOCAL_MODULE := boost_#{name}_static"
        f.puts "LOCAL_SRC_FILES := libs/$(TARGET_ARCH_ABI)/libboost_#{name}.a"
        f.puts 'LOCAL_EXPORT_C_INCLUDES := $(LOCAL_PATH)/include'
        f.puts 'ifneq (,$(filter clang%,$(NDK_TOOLCHAIN_VERSION)))'
        f.puts 'LOCAL_EXPORT_LDLIBS := -latomic'
        f.puts 'endif'
        @lib_deps[name].each do |dep|
          f.puts "LOCAL_STATIC_LIBRARIES += boost_#{dep}_static"
        end
        f.puts 'include $(PREBUILT_STATIC_LIBRARY)'
        f.puts ''
        f.puts 'include $(CLEAR_VARS)'
        f.puts "LOCAL_MODULE := boost_#{name}_shared"
        f.puts "LOCAL_SRC_FILES := libs/$(TARGET_ARCH_ABI)/libboost_#{name}.so"
        f.puts 'LOCAL_EXPORT_C_INCLUDES := $(LOCAL_PATH)/include'
        f.puts 'ifneq (,$(filter clang%,$(NDK_TOOLCHAIN_VERSION)))'
        f.puts 'LOCAL_EXPORT_LDLIBS := -latomic'
        f.puts 'endif'
        @lib_deps[name].each do |dep|
          f.puts "LOCAL_SHARED_LIBRARIES += boost_#{dep}_shared"
        end
        f.puts 'include $(PREBUILT_SHARED_LIBRARY)'
        if exclude_flag
          f.puts 'endif'
          exclude_flag = false
        end
        # todo: do not output empty lines for the last element
        f.puts ''
        f.puts ''
      end
    end
  end
end

__END__
From ee108969816ed2aad8a4e8495b1050047abe72af Mon Sep 17 00:00:00 2001
From: Dmitry Moskalchuk <dm@crystax.net>
Date: Mon, 7 Sep 2015 00:42:35 +0300
Subject: [PATCH] [android][x86_64] Workaround for clang bug

See https://tracker.crystax.net/issues/1044

Signed-off-by: Dmitry Moskalchuk <dm@crystax.net>
---
 libs/locale/src/util/numeric.hpp | 22 ++++++++++++++++++++++
 1 file changed, 22 insertions(+)

diff --git a/libs/locale/src/util/numeric.hpp b/libs/locale/src/util/numeric.hpp
index 892427d..fb7c019 100644
--- a/libs/locale/src/util/numeric.hpp
+++ b/libs/locale/src/util/numeric.hpp
@@ -254,6 +254,24 @@ private:

 };  /// num_format

+#if defined(__ANDROID__) && defined(__x86_64__) && defined(__clang__)
+namespace base_num_parse_details
+{
+
+template <typename ValueType>
+struct cast_helper
+{
+    static ValueType cast(long double val) { return static_cast<ValueType>(val); }
+};
+
+template <>
+struct cast_helper<unsigned short>
+{
+    static unsigned short cast(long double val) { return static_cast<unsigned short>(static_cast<unsigned int>(val)); }
+};
+
+} // namespace base_num_parse_details
+#endif /* defined(__ANDROID__) && defined(__x86_64__) && defined(__clang__) */

 template<typename CharType>
 class base_num_parse : public std::num_get<CharType>
@@ -342,7 +360,11 @@ private:
                 else
                     in = parse_currency<true>(in,end,ios,err,ret_val);
                 if(!(err & std::ios_base::failbit))
+#if defined(__ANDROID__) && defined(__x86_64__) && defined(__clang__)
+                    val = base_num_parse_details::cast_helper<ValueType>::cast(ret_val);
+#else
                     val = static_cast<ValueType>(ret_val);
+#endif
                 return in;
             }

--
2.6.4
