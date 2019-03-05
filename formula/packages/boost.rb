class Boost < Package

  desc "Boost libraries built without ICU4C"
  homepage "http://www.boost.org"
  url "https://downloads.sourceforge.net/project/boost/boost/${version}/boost_${block}.tar.bz2" do |r| r.version.gsub('.', '_') end

  release '1.67.0', crystax: 2

  # todo: add versions, like this: python:2.7.*, python:3.*.*
  depends_on 'python'
  depends_on 'xz'

  build_options build_outside_source_tree: true,
                setup_env:                 false,
                copy_installed_dirs:       [],
                gen_android_mk:            false,
                wrapper_remove_args:       ['-m32', '-m64', '-single_module', '-lpthread', '-lutil'],
                wrapper_replace_args:      { '-dynamiclib' => '-shared', '-undefined' => '-u' }

  build_copy 'LICENSE_1_0.txt'

  STATIC_ONLY = ['exception', 'test_exec_monitor']

  @built_libraries = Hash.new { |h,k| h[k] = [] }

  def self.built_libraries
    @built_libraries
  end

  def built_libraries
    self.class.built_libraries
  end

  class BuildOptions
    attr_reader :toolchains

    def initialize
      @toolchains = []
    end

    def parse(opts)
      toolchain_names = []

      opts.each do |opt|
        case opt
        when /^--boost-toolchains=/
          toolchain_names = opt.split('=')[1].split(',')
        else
          raise "unknown boost build option: #{opt}"
        end
      end

      if toolchain_names.empty?
        @toolchains = Build::TOOLCHAIN_LIST
      else
        toolchain_names.each do |tn|
          ta = Build::TOOLCHAIN_LIST.select { |t| t.to_s == tn }.uniq
          raise "unsupported toolchain #{tn}" if ta.empty?
          @toolchains << ta[0]
        end
      end
    end

    def lines
      ["build with toolchains: #{@toolchains.join(', ')}"]
    end
  end

  def package_build_options
    BuildOptions.new
  end

  def initialize(path)
    super path
    @lib_deps = Hash.new([])
  end

  def pre_build(_, release)
    src_dir = "#{build_base_dir}/src"
    FileUtils.cp_r "#{source_directory(release)}/.", src_dir

    host_tc_dir = "#{src_dir}/host-bin"
    FileUtils.mkdir_p host_tc_dir
    host_cc = "#{host_tc_dir}/cc"
    Build.gen_host_compiler_wrapper host_cc, 'gcc'

    FileUtils.cd(src_dir) do
      build_env['PATH'] = "#{host_tc_dir}:#{ENV['PATH']}"
      system './bootstrap.sh',  '--with-toolset=cc'
    end

    # todo: fix mpi?
    gen_user_config_jam src_dir

    src_dir
  end

  def post_build(pkg_dir, release)
    # puts ''
    # built_libraries.keys.each do |key|
    #   puts "#{key}: #{built_libraries[key].join(',')}"
    # end

    gen_android_mk pkg_dir, release

    'OK'
  end

  def build_for_abi(abi, _toolchain, release, options)
    arch = Build.arch_for_abi(abi)
    bjam_arch, bjam_abi = bjam_data(arch)

    src_dir = pre_build_result
    base_work_dir = Dir.pwd

    common_args = [ "-d+2",
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
                    "--user-config=#{src_dir}/user-config.jam",
                    "--layout=system"
                  ]

    options.package_options[self.name].toolchains.each do |toolchain|
      stl_name = toolchain.stl_name
      puts "    using C++ standard library: #{stl_name}"
      work_dir = "#{base_work_dir}/#{stl_name}"
      FileUtils.mkdir_p work_dir

      build_env.clear
      cxx = "#{work_dir}/#{toolchain.cxx_compiler_name}"
      cxxflags = cxx_flags(toolchain, abi) + " -I#{target_dep_include_dir('xz')}"

      build_env['PATH'] = "#{work_dir}:#{ENV['PATH']}"

      # build without python
      prefix_dir = "#{work_dir}/install"
      build_dir = "#{work_dir}/build"
      ldflags = ld_flags(toolchain, abi)

      gen_project_config_jam src_dir, arch, abi, stl_name, { ver: :none }
      Build.gen_compiler_wrapper cxx, toolchain.cxx_compiler(arch, abi), toolchain, build_options, cxxflags, ldflags
      puts "      building boost libraries"
      args = common_args + without_libs(release, arch) + ['--without-mpi', '--without-python', "--build-dir=#{build_dir}", "--prefix=#{prefix_dir}"]
      FileUtils.cd(src_dir) { system "./b2", *args, 'install' }

      # build python libs
      python_versions.each do |py_ver|
        py_dir = "#{Global::HOLD_DIR}/python/#{py_ver}"
        py_lib_dir = "#{py_dir}/shared/#{abi}/libs"
        ldflags[:after] = "-L#{py_lib_dir} -l#{python_lib_name(py_ver)} " + ldflags[:after]
        Build.gen_compiler_wrapper cxx, toolchain.cxx_compiler(arch, abi), toolchain, build_options, cxxflags, ldflags
        py_data = { ver:     py_ver,
                    abi:     python_abi(py_ver),
                    dir:     py_dir,
                    lib_dir: py_lib_dir,
                    inc_dir: "#{py_dir}/include/python"
                  }
        gen_project_config_jam src_dir, arch, abi, stl_name, py_data
        args = common_args + ["--build-dir=#{build_dir}-#{py_ver}", "--prefix=#{prefix_dir}-#{py_ver}", '--with-python']
        puts "      building python library for python #{py_ver}"
        FileUtils.cd(src_dir) { system "./b2", *args, 'install' }
        Dir["#{prefix_dir}-#{py_ver}/lib/*"].each { |p| FileUtils.copy_entry p, "#{prefix_dir}/lib/#{File.basename(p)}" }
      end

      # find and store dependencies for the built libraries
      @lib_deps = Hash.new([])
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
      # run ranlib and update built libraries list
      FileUtils.cd(libs_dir) do
        ranlib = toolchain.tool(arch, 'ranlib')
        libs = Dir['*.a']
        libs.each { |f| system ranlib, f }
        update_built_libraries toolchain, abi, libs
      end
    end
  end

  def update_built_libraries(toolchain, abi, libs)
    libs.map { |e| e.sub(/^libboost_/, '').sub(/\.a$/, '') }.sort.uniq.each do |lib|
      built_libraries[lib] << "#{toolchain}_#{abi}"
    end
  end

  def cxx_flags(toolchain, abi)
    toolchain.cflags(abi) + ' ' +
      "--sysroot=#{Build.sysroot(abi)}" + ' ' +
      toolchain.search_path_for_stl_includes(abi) + ' ' +
      '-fPIC -Wno-long-long'
  end

  def ld_flags(toolchain, abi)
    { before: "#{toolchain.ldflags(abi)} --sysroot=#{Build.sysroot(abi)} #{toolchain.search_path_for_stl_libs(abi)} -L#{target_dep_lib_dir('xz', abi)}",
      after:  "-l#{toolchain.stl_lib_name}_shared"
    }
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
    exclude_libs(release).select { |_, v| v.include? arch.name }.keys.map { |lib| "--without-#{lib}" }
  end

  def exclude_libs(release)
    exclude = {}
    major, minor, _ = release.version.split('.').map { |a| a.to_i }

    # Boost.Fiber fails to build for mips using gcc 6: Error: opcode not supported on this processor: mips32 (mips32) `pause'
    # check next versions
    if major == 1 and minor <= 69
      exclude['fiber'] = ['mips']
    end

    exclude
  end

  def gen_project_config_jam(dir, arch, abi, stl_name, python_data)
    File.open("#{dir}/project-config.jam", 'w') do |f|
      f.puts "import option ;"
      f.puts "import feature ;"
      unless python_data[:ver] == :none
        #f.puts "import python ;" unless python_data[:ver] =~ /^2\..*/
        f.puts "using python : #{python_data[:abi]} : #{python_data[:dir]} : #{python_data[:inc_dir]} : #{python_data[:lib_dir]} : <target-os>android ;"
      end
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
    FileUtils.touch "#{dir}/user-config.jam"
    # 'using mpi' break build on linux because build system
    # tries to use locally found (system) mpi libs
    #File.open("#{dir}/user-config.jam", 'w') { |f| f.puts "using mpi ;" }
  end

  def gen_android_mk(pkg_dir, release)
    #exclude = exclude_libs(release)

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
      f.puts '__boost_toolchain_version := $(strip \\'
      f.puts '    $(if $(filter c++_%,$(APP_STL)),\\'
      f.puts '        $(if $(filter clang%,$(NDK_TOOLCHAIN_VERSION)),$(patsubst clang%,%,$(NDK_TOOLCHAIN_VERSION)),$(DEFAULT_LLVM_VERSION)),\\'
      f.puts '        $(if $(filter clang%,$(NDK_TOOLCHAIN_VERSION)),$(DEFAULT_GCC_VERSION),$(or $(NDK_TOOLCHAIN_VERSION),$(DEFAULT_GCC_VERSION)))\\'
      f.puts '    ))'
      f.puts ''
      f.puts '__boost_toolchain_abi_pair := $(strip \\'
      f.puts '    $(strip $(if $(filter c++_%,$(APP_STL)),\\'
      f.puts '        clang,\\'
      f.puts '        gcc\\'
      f.puts '    ))$(__boost_toolchain_version)_$(TARGET_ARCH_ABI)\\'
      f.puts '    )'
      f.puts ''
      f.puts '__boost_libstdcxx_subdir := $(strip \\'
      f.puts '    $(strip $(if $(filter c++_%,$(APP_STL)),\\'
      f.puts '        llvm,\\'
      f.puts '        gnu\\'
      f.puts '    ))-$(__boost_toolchain_version)\\'
      f.puts '    )'
      f.puts ''
      built_libraries.keys.each do |name|
        # exclude_flag = false
        # if archs = exclude[name]
        #   exclude_flag = true
        #   f.puts "ifeq (,$(filter #{archs.join(' ')},$(TARGET_ARCH_ABI)))"
        # end
        f.puts "ifneq (,$(filter $(__boost_toolchain_abi_pair),#{built_libraries[name].join(' ')}))"
        f.puts 'include $(CLEAR_VARS)'
        f.puts "LOCAL_MODULE := boost_#{name}_static"
        f.puts "LOCAL_SRC_FILES := libs/$(TARGET_ARCH_ABI)/$(__boost_libstdcxx_subdir)/libboost_#{name}.a"
        f.puts 'LOCAL_EXPORT_C_INCLUDES := $(LOCAL_PATH)/include'
        f.puts 'ifneq (,$(filter clang%,$(NDK_TOOLCHAIN_VERSION)))'
        f.puts 'LOCAL_EXPORT_LDLIBS := -latomic'
        f.puts 'endif'
        @lib_deps[name].each do |dep|
          f.puts "LOCAL_STATIC_LIBRARIES += boost_#{dep}_static"
        end
        f.puts 'include $(PREBUILT_STATIC_LIBRARY)'
        f.puts ''
        unless STATIC_ONLY.include? name
          f.puts 'include $(CLEAR_VARS)'
          f.puts "LOCAL_MODULE := boost_#{name}_shared"
          f.puts "LOCAL_SRC_FILES := libs/$(TARGET_ARCH_ABI)/$(__boost_libstdcxx_subdir)/libboost_#{name}.so"
          f.puts 'LOCAL_EXPORT_C_INCLUDES := $(LOCAL_PATH)/include'
          f.puts 'ifneq (,$(filter clang%,$(NDK_TOOLCHAIN_VERSION)))'
          f.puts 'LOCAL_EXPORT_LDLIBS := -latomic'
          f.puts 'endif'
          @lib_deps[name].each do |dep|
            f.puts "LOCAL_SHARED_LIBRARIES += boost_#{dep}_shared"
          end
          f.puts 'include $(PREBUILT_SHARED_LIBRARY)'
        end
        f.puts 'endif'
        # if exclude_flag
        #   f.puts 'endif'
        #   exclude_flag = false
        # end
        # todo: do not output empty lines for the last element
        f.puts ''
        f.puts ''
      end
    end
  end

  def python_versions
    # todo: get last versions for 2.* and 3.*
    ['2.7.11', '3.5.1']
  end

  def python_lib_name(ver)
    abi = python_abi(ver)
    case abi
    when /^2\..*/
      "python#{abi}"
    when /^3\..*/
      "python#{abi}m"
    else
      raise "unsupported python version: #{ver}"
    end
  end

  def python_abi(ver)
    v = ver.split('.')
    "#{v[0]}.#{v[1]}"
  end

  def build_test(test_dir, abi, toolchain)
    test_name = File.basename(test_dir)
    unless test_name == 'dependencies'
      super test_dir, abi, toolchain
    else
      ['gnustl', 'c++'].each do |cxx_runtime|
        test_log_puts "        C++ runtime: #{cxx_runtime}"

        ['shared', 'static'].each do |cxx_runtime_type|
          test_log_puts "          C++ runtime type: #{cxx_runtime_type}"
          dir = "#{File.dirname(test_dir)}-#{cxx_runtime}-#{cxx_runtime_type}"
          FileUtils.mkdir_p dir
          FileUtils.cp_r test_dir, dir

          cxx_test_dir = "#{dir}/#{test_name}"
          replace_lines_in_file("#{cxx_test_dir}/jni/Android.mk") do |line|
            case line
            when /\${libtype}/
              line.gsub '${libtype}', cxx_runtime_type
            else
              line
            end
          end

          args = ["APP_ABI=#{abi}",
                  "NDK_TOOLCHAIN_VERSION=#{toolchain.gsub(/gcc/, '')}",
                  "APP_STL=#{cxx_runtime}_#{cxx_runtime_type}"
                 ]
          ndk_build '-C', cxx_test_dir, 'V=1', *args
        end
      end
    end
  end

  def preprocess_test(dir, release, abi, toolchain, cxx_runtime, cxx_runtime_type)
    super dir, release, abi, toolchain, cxx_runtime, cxx_runtime_type

  end
end
