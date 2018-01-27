class Python < Package

  desc "Interpreted, interactive, object-oriented programming language"
  homepage "https://www.python.org"
  url "https://www.python.org/ftp/python/${version}/Python-${version}.tgz"

  release version: '2.7.11', crystax_version: 2
  release version: '3.5.1',  crystax_version: 2

  depends_on 'sqlite'
  depends_on 'openssl', version: /^1\.0/

  build_copy 'LICENSE'
  build_options sysroot_in_cflags:   false,
                copy_installed_dirs: [],
                gen_android_mk:      false

  def pre_build(src_dir, release)
    build_dir = "#{build_base_dir}/native"
    FileUtils.mkdir_p build_dir
    FileUtils.cp_r "#{src_dir}/.", build_dir

    # use system compiler on darwin to build 3.5.1
    # prebuilt gcc builds python that fails to run
    unless Global::OS == 'darwin' and release.version == '3.5.1'
      gcc_path = "#{build_dir}/gcc"
      gxx_path = "#{build_dir}/g++"

      Build.gen_host_compiler_wrapper gcc_path, 'gcc'
      Build.gen_host_compiler_wrapper gxx_path, 'g++'

      build_env['PATH'] = "#{build_dir}:#{ENV['PATH']}"
      build_env['CC']   = gcc_path
      build_env['CXX']  = gxx_path

      platform = Platform.new(Global::PLATFORM_NAME)

      if platform.target_os == 'darwin'
        build_env['DARWIN_SYSROOT'] = platform.sysroot
        build_env['MACOSX_DEPLOYMENT_TARGET'] = '10.6'
      end
    end

    FileUtils.cd(build_dir) do
      system './configure'
      system 'make', '-j', num_jobs
    end

    build_dir
  end

  def post_build(pkg_dir, release)
    gen_android_mk pkg_dir, release
  end

  attr_reader :install_include_dir, :install_frozen_include_dir
  attr_reader :pybin_install_shared_dir, :pybin_install_shared_libs_dir, :pybin_install_shared_modules_dir
  attr_reader :pybin_install_static_libs_dir, :pybin_install_static_bin_dir
  attr_reader :support_dir
  attr_reader :major_ver, :python_abi

  def build_for_abi(abi, toolchain, release, _host_dep_dirs, target_dep_dirs, _options)
    src_dir = build_dir_for_abi(abi)
    build_dir = "#{src_dir}/build"

    @install_include_dir              = "#{package_dir}/include/python"
    @install_frozen_include_dir       = "#{package_dir}/include/frozen"
    @pybin_install_shared_dir         = "#{package_dir}/shared/#{abi}"
    @pybin_install_shared_libs_dir    = "#{pybin_install_shared_dir}/libs"
    @pybin_install_shared_modules_dir = "#{pybin_install_shared_dir}/modules"
    @pybin_install_static_libs_dir    = "#{package_dir}/static/libs/#{abi}"
    @pybin_install_static_bin_dir     = "#{package_dir}/static/bin/#{abi}"

    @support_dir = "#{Global::NDK_DIR}/build/instruments/build-python" # todo: copy somewhere inside crew?
    @major_ver, @python_abi = python_version_data(release)

    #
    # Step 1: configure
    #
    build_config_dir      = "#{build_dir}/config"
    build_core_shared_dir = "#{build_dir}/core-shared"
    build_core_static_dir = "#{build_dir}/core-static"
    FileUtils.mkdir_p [build_config_dir, build_core_shared_dir, build_core_static_dir]

    config_site = "#{build_config_dir}/config.site"
    gen_config_site config_site, major_ver

    python_for_build = "#{pre_build_result}/python"
    build_env['CONFIG_SITE'] = config_site
    build_env['PYTHON_FOR_BUILD'] = python_for_build
    #build_env['PGEN_FOR_BUILD'] = "#{pre_build_result}/Parser/pgen"

    args = ["--prefix=#{build_config_dir}/install",
            "--host=#{host_for_abi(abi)}",
            "--build=#{python_build_platform}",
            "--enable-shared",
            "--with-threads",
            "--enable-ipv6",
            "--without-ensurepip"
           ]
    args << (major_ver == 2) ? "--enable-unicode=ucs4" : "--with-computed-gotos"

    FileUtils.cd(build_config_dir) { system "#{src_dir}/configure", *args }

    #
    # Step 2: build shared and static python-core
    #
    if major_ver == 2
      py_c_getpath = "#{support_dir}/getpath.c.#{python_abi}"
      py_c_frozen  = "#{support_dir}/frozen.c.#{python_abi}"
    else
      py_c_getpath = "#{support_dir}/getpath.c.3.x"
      py_c_frozen  = "#{support_dir}/frozen.c.3.x"
    end
    py_c_config_file = "#{support_dir}/config.c.#{python_abi}"
    pyconfig_h_file  = "#{support_dir}/pyconfig.h"
    pyconfig_for_abi = "pyconfig_#{abi.gsub('-', '_')}.h"

    # shared python-core
    build_core_shared_jni_dir = "#{build_core_shared_dir}/jni"
    FileUtils.mkdir_p build_core_shared_jni_dir

    FileUtils.cp py_c_config_file,                 "#{build_core_shared_jni_dir}/config.c"
    FileUtils.cp py_c_frozen,                      "#{build_core_shared_jni_dir}/frozen.c"
    FileUtils.cp py_c_getpath,                     "#{build_core_shared_jni_dir}/getpath.c"
    FileUtils.cp "#{build_config_dir}/pyconfig.h", "#{build_core_shared_jni_dir}/#{pyconfig_for_abi}"
    FileUtils.cp pyconfig_h_file,                  build_core_shared_jni_dir

    gen_core_android_mk build_core_shared_jni_dir, src_dir, :shared
    ndk_build           build_core_shared_dir, abi

    if not Dir.exists? install_include_dir
      FileUtils.mkdir_p install_include_dir
      FileUtils.cp   "#{support_dir}/pyconfig.h", install_include_dir
      FileUtils.cp_r "#{src_dir}/Include/.",      install_include_dir
    end
    FileUtils.cp "#{build_core_shared_jni_dir}/#{pyconfig_for_abi}", install_include_dir
    FileUtils.mkdir_p pybin_install_shared_libs_dir
    # todo: while take lib from objs dir, not from libs dir?
    FileUtils.cp "#{built_objs_dir(build_core_shared_dir, abi)}/lib#{python_core_module_name}.so", pybin_install_shared_libs_dir

    # static python-core
    build_core_static_jni_dir = "#{build_core_static_dir}/jni"
    FileUtils.mkdir_p build_core_static_jni_dir

    FileUtils.cp py_c_config_file,                 "#{build_core_static_jni_dir}/config.c"
    FileUtils.cp py_c_frozen,                      "#{build_core_static_jni_dir}/frozen.c"
    FileUtils.cp py_c_getpath,                     "#{build_core_static_jni_dir}/getpath.c"
    FileUtils.cp "#{build_config_dir}/pyconfig.h", "#{build_core_static_jni_dir}/#{pyconfig_for_abi}"
    FileUtils.cp "#{support_dir}/pyconfig.h",      build_core_static_jni_dir

    gen_core_android_mk build_core_static_jni_dir, src_dir, :static
    ndk_build build_core_static_dir, abi

    FileUtils.mkdir_p pybin_install_static_libs_dir
    FileUtils.cp "#{build_core_static_dir}/obj/local/#{abi}/lib#{python_core_module_name}.a", pybin_install_static_libs_dir

    #
    # Step 3: build python stdlib
    #
    pystdlib_zipfile = "#{pybin_install_shared_dir}/stdlib.zip"
    #log "Install python$PYTHON_ABI-$ABI stdlib as $PYSTDLIB_ZIPFILE"
    args = ['--pysrc-root', src_dir, '--output-zip', pystdlib_zipfile]
    args << '--py2' if major_ver == 2
    system python_for_build, "#{support_dir}/build_stdlib.py", *args

    # freeze python stdlib
    build_stdlib_freeze_dir = "#{build_dir}/stdlib-freeze"
    #log "Freeze python$PYTHON_ABI stdlib"
    FileUtils.mkdir_p build_stdlib_freeze_dir
    args = ["#{support_dir}/freeze_stdlib.py", '--stdlib-dir', "#{src_dir}/Lib", '--output-dir', build_stdlib_freeze_dir]
    args << '--py2' if major_ver == 2
    system python_for_build, *args

    FileUtils.mkdir_p install_frozen_include_dir
    unless File.exist? "#{install_frozen_include_dir}/python-stdlib.h"
      FileUtils.cp "#{build_stdlib_freeze_dir}/python-stdlib.h", install_frozen_include_dir
    end

    # build frozen python stdlib as static library
    build_stdlib_frozen_dir = "#{build_dir}/stdlib-frozen"
    build_stdlib_frozen_jni_dir = "#{build_stdlib_frozen_dir}/jni"
    FileUtils.mkdir_p build_stdlib_frozen_jni_dir
    stdlib_frozen_src_list = File.read("#{build_stdlib_freeze_dir}/python-stdlib.list").split("\n").map { |l| l.strip }
    FileUtils.cd(build_stdlib_freeze_dir) do
      stdlib_frozen_src_list.each { |f| FileUtils.cp f, build_stdlib_frozen_jni_dir }
    end

    gen_frozen_stdlib_android_mk(build_stdlib_frozen_jni_dir, stdlib_frozen_src_list)
    ndk_build build_stdlib_frozen_dir, abi

    #log "Install python$PYTHON_ABI-$ABI frozen stdlib in $PYBIN_INSTALLDIR_STATIC_LIBS"
    FileUtils.cp "#{build_stdlib_frozen_dir}/obj/local/#{abi}/libpython#{python_abi}_stdlib.a", pybin_install_static_libs_dir

    #
    # Step 4: build dynamic python-interpreter
    #
    build_dynamic_interpreter_dir     = "#{build_dir}/interpreter"
    build_dynamic_interpreter_jni_dir = "#{build_dynamic_interpreter_dir}/jni"
    obj_dynamic_interpreter_dir       = "#{build_dynamic_interpreter_dir}/obj/local/#{abi}"

    FileUtils.mkdir_p build_dynamic_interpreter_jni_dir
    py_c_dynamic_interpreter_file = File.join(src_dir, (major_ver == 2) ? 'Modules' : 'Programs', 'python.c')
    FileUtils.cp py_c_dynamic_interpreter_file, "#{build_dynamic_interpreter_jni_dir}/interpreter.c"

    gen_dynamic_interpreter_android_mk build_dynamic_interpreter_jni_dir
    ndk_build build_dynamic_interpreter_jni_dir, abi

    #log "Install python$PYTHON_ABI-$ABI interpreter in $PYBIN_INSTALLDIR"
    FileUtils.cp "#{obj_dynamic_interpreter_dir}/python", "#{pybin_install_shared_dir}/python.bin"
    gen_python_dynamic_interpreter_wrapper

    #
    # Step 5: site-packages
    #
    site_install_dir = "#{pybin_install_shared_dir}/site-packages"
    FileUtils.mkdir_p site_install_dir
    FileUtils.cp "#{src_dir}/Lib/site-packages/README", site_install_dir

    #
    # Step 6: build python modules
    #
    FileUtils.mkdir_p pybin_install_shared_modules_dir
    openssl_dir = import_module_path(target_dep_dirs['openssl'])
    sqlite_dir = import_module_path(target_dep_dirs['sqlite'])
    #
    build_module_ctypes          src_dir, build_dir, abi
    build_module_multiprocessing src_dir, build_dir, abi
    build_module_socket          src_dir, build_dir, abi
    build_module_ssl             src_dir, build_dir, abi, openssl_dir
    build_module_sqlite3         src_dir, build_dir, abi, sqlite_dir
    build_module_pyexpat         src_dir, build_dir, abi
    build_module_select          src_dir, build_dir, abi
    build_module_unicodedata     src_dir, build_dir, abi

    #
    # Step 7: build static interpreter
    #
    build_static_interpreter_dir     = "#{build_dir}/interpreter-static"
    build_static_interpreter_jni_dir = "#{build_static_interpreter_dir}/jni"
    obj_static_interpreter_dir       = "#{build_static_interpreter_dir}/obj/local/#{abi}"

    FileUtils.mkdir_p build_static_interpreter_jni_dir
    py_c_static_interpreter_file = "#{support_dir}/interpreter-static.c." + ((major_ver == 2) ? '2.7' : '3.x')
    FileUtils.cp py_c_static_interpreter_file, "#{build_static_interpreter_jni_dir}/interpreter.c"
    FileUtils.cp "#{build_stdlib_freeze_dir}/python-stdlib.c", build_static_interpreter_jni_dir

    gen_static_interpreter_android_mk build_static_interpreter_jni_dir, abi, src_dir, openssl_dir, sqlite_dir
    ndk_build build_static_interpreter_jni_dir, abi, "APP_PLATFORM=#{exe_platform(abi)}", 'APP_PIE=true'

    FileUtils.mkdir_p pybin_install_static_bin_dir
    FileUtils.cp "#{obj_static_interpreter_dir}/python", pybin_install_static_bin_dir
  end

  def python_version_data(release)
    v = release.version.split('.')
    [v[0].to_i, "#{v[0]}.#{v[1]}"]
  end

  def gen_config_site(filename, major_ver)
    File.open(filename, 'w') do |f|
      f.puts 'ac_cv_file__dev_ptmx=no'
      f.puts 'ac_cv_file__dev_ptc=no'
      f.puts 'ac_cv_func_gethostbyname_r=no'
      f.puts 'ac_cv_func_faccessat=no' if major_ver == 3
    end
  end

  def python_build_platform
    Utils.run_command('./config.guess').strip
  end

  def python_core_module_name
    major_ver == 2 ? "python#{python_abi}"  : "python#{python_abi}m"
  end

  def python_soabi(major_ver, python_abi)
    major_ver == 2 ? "cpython-#{python_abi}m" : nil
  end

  def gen_android_mk(pkg_dir, release)
    formulary = Formulary.new
    openssl_rel = formulary['target/openssl'].highest_installed_release
    sqlite_rel  = formulary['target/sqlite'].highest_installed_release

    v = release.version.split('.')
    vs = v[0] +'.' + v[1]
    vs += 'm' if (v[0].to_i > 2)

    File.open("#{pkg_dir}/Android.mk", "w") do |f|
      f.puts Build::COPYRIGHT_STR
      f.puts ''
      f.puts "# bdc: openssl #{openssl_rel}"
      f.puts "# bdc: sqlite  #{sqlite_rel}"
      f.puts ''
      f.puts 'LOCAL_PATH := $(call my-dir)'
      f.puts ''
      f.puts 'include $(CLEAR_VARS)'
      f.puts 'LOCAL_MODULE := python_shared'
      f.puts "LOCAL_SRC_FILES := libs/$(TARGET_ARCH_ABI)/libpython#{vs}.so"
      f.puts 'LOCAL_EXPORT_C_INCLUDES := $(LOCAL_PATH)/include/python'
      f.puts 'include $(PREBUILT_SHARED_LIBRARY)'
      f.puts ''
      f.puts 'include $(CLEAR_VARS)'
      f.puts 'LOCAL_MODULE := python_static'
      f.puts "LOCAL_SRC_FILES := static/libs/$(TARGET_ARCH_ABI)/libpython#{vs}.a"
      f.puts 'LOCAL_EXPORT_C_INCLUDES := $(LOCAL_PATH)/include/python'
      f.puts 'include $(PREBUILT_STATIC_LIBRARY)'
    end
  end

  def gen_core_android_mk(dir, src_dir, core_type)
    filename = File.join(dir, 'Android.mk')

    local_cflags  = '-DPy_BUILD_CORE -DPLATFORM="linux"'
    local_cflags += ' -DPy_ENABLE_SHARED'                                     if core_type == :shared
    local_cflags += " -DSOABI=\\\"#{python_soabi(major_ver, python_abi)}\\\"" if major_ver > 2

    File.open(filename, 'w') do |f|
      f.puts 'LOCAL_PATH := $(call my-dir)'
      f.puts 'include $(CLEAR_VARS)'
      f.puts "LOCAL_MODULE := #{python_core_module_name}"
      f.puts "MY_PYTHON_SRC_ROOT := #{src_dir}"
      f.puts 'LOCAL_C_INCLUDES := $(MY_PYTHON_SRC_ROOT)/Include $(MY_PYTHON_SRC_ROOT)/Python'
      f.puts "LOCAL_CFLAGS := #{local_cflags}"
      f.puts 'LOCAL_LDLIBS := -lz'
      f.puts File.read("#{support_dir}/android.mk.#{python_abi}")
      f.puts ''
      f.puts 'LOCAL_SRC_FILES := config.c frozen.c getpath.c $(MY_PYCORE_SRC_FILES)'
      f.puts ''
      f.puts "include $(BUILD_#{core_type.to_s.upcase}_LIBRARY)"
    end
  end

  def gen_frozen_stdlib_android_mk(dir, src_list)
    filename = File.join(dir, 'Android.mk')
    File.open(filename, 'w') do |f|
      f.puts 'LOCAL_PATH := $(call my-dir)'
      f.puts 'include $(CLEAR_VARS)'
      f.puts "LOCAL_MODULE := python#{python_abi}_stdlib"
      f.puts 'LOCAL_SRC_FILES := \\'
      src_list.each { |src| f.puts "  #{src} \\" }
      f.puts
      f.puts 'include $(BUILD_STATIC_LIBRARY)'
    end
  end

  def gen_dynamic_interpreter_android_mk(dir)
    filename = File.join(dir, 'Android.mk')
    File.open(filename, 'w') do |f|
      f.puts 'LOCAL_PATH := $(call my-dir)'
      f.puts 'include $(CLEAR_VARS)'
      f.puts 'LOCAL_MODULE := python'
      f.puts 'LOCAL_SRC_FILES := interpreter.c'
      f.puts 'LOCAL_SHARED_LIBRARIES := python_shared'
      f.puts "LOCAL_LDLIBS := -lz"
      f.puts 'include $(BUILD_EXECUTABLE)'
      f.puts python_shared_section
    end
  end

  def ndk_build(build_dir, abi, *args)
    system "#{Global::NDK_DIR}/ndk-build", '-C', build_dir, "-j#{num_jobs}", "APP_ABI=#{abi}", 'V=1', *args
  end

  def built_objs_dir(build_dir, abi)
    "#{build_dir}/obj/local/#{abi}"
  end

  def gen_python_dynamic_interpreter_wrapper
    filename = File.join(pybin_install_shared_dir, 'python')
    File.open(filename, 'w') do |f|
      f.puts '#!/system/bin/sh'
      f.puts 'DIR_HERE=$(cd ${0%python} && pwd)'
      f.puts 'export LD_LIBRARY_PATH=$DIR_HERE/libs'
      f.puts 'exec $DIR_HERE/python.bin $*'
    end
    FileUtils.chmod '+x', filename
  end

  def build_module_ctypes(src_dir, build_dir, abi)
    base_dir         = "#{build_dir}/ctypes"
    config_dir       = "#{base_dir}/config"
    build_shared_dir = "#{base_dir}/shared"
    build_static_dir = "#{base_dir}/static"

    FileUtils.mkdir_p config_dir

    args = ["--host=#{host_for_abi(abi)}",
            "--build=#{python_build_platform}",
            "--prefix=#{config_dir}/install"
           ]
    FileUtils.cd(config_dir) { system "#{src_dir}/Modules/_ctypes/libffi/configure", *args }

    src_list = ffi_src_list(abi).map { |f| "_ctypes/libffi/#{f}" } +
               [ 'callbacks.c', 'callproc.c', 'cfield.c', 'malloc_closure.c', 'stgdict.c', '_ctypes.c'].map { |f| "_ctypes/#{f}" }
    c_includes = ['$(LOCAL_PATH)/include']

    # shared
    shared_jni_dir = "#{build_shared_dir}/jni"
    shared_inc_dir = "#{shared_jni_dir}/include"
    FileUtils.mkdir_p shared_inc_dir
    FileUtils.cp ["#{config_dir}/fficonfig.h"] + Dir["#{config_dir}/include/*.h"], shared_inc_dir

    module_name = '_ctypes'
    gen_module_android_mk "#{shared_jni_dir}/Android.mk", module_name, src_dir, src_list, { c_includes: c_includes, module_type: :shared }
    ndk_build build_shared_dir, abi
    FileUtils.cp "#{built_objs_dir(build_shared_dir, abi)}/lib#{module_name}.so", "#{pybin_install_shared_modules_dir}/#{module_name}.so"

    # static
    static_jni_dir = "#{build_static_dir}/jni"
    static_inc_dir = "#{static_jni_dir}/include"
    FileUtils.mkdir_p static_inc_dir
    FileUtils.cp ["#{config_dir}/fficonfig.h"] + Dir["#{config_dir}/include/*.h"], static_inc_dir

    gen_module_android_mk "#{static_jni_dir}/Android.mk", static_module_name(module_name), src_dir, src_list, c_includes: c_includes, module_type: :static
    ndk_build build_static_dir, abi
    FileUtils.cp "#{built_objs_dir(build_static_dir, abi)}/lib#{static_module_name(module_name)}.a", pybin_install_static_libs_dir
    generate_python_module_header module_name
  end

  def ffi_src_list(abi)
    src = ['src/prep_cif.c']
    case abi
    when 'x86'       then src += ['src/x86/ffi.c', 'src/x86/sysv.S', 'src/x86/win32.S']
    when 'x86_64'    then src += ['src/x86/ffi64.c', 'src/x86/unix64.S']
    when /^armeabi/  then src += ['src/arm/ffi.c', 'src/arm/sysv.S']
    when 'arm64-v8a' then src += ['src/aarch64/ffi.c', 'src/aarch64/sysv.S']
    when 'mips'      then src += ['src/mips/ffi.c', 'src/mips/o32.S']
    when 'mips64'    then src += ['src/mips/ffi.c', 'src/mips/o32.S', 'src/mips/n32.S']
    else
      raise "unknown ABI #{abi}"
    end
    src
  end

  def build_module_multiprocessing(src_dir, build_dir, abi)
    base_dir = "#{build_dir}/multiprocessing"
    build_shared_dir = "#{base_dir}/shared"
    build_static_dir = "#{base_dir}/static"

    src_list = ['_multiprocessing/multiprocessing.c', '_multiprocessing/semaphore.c']
    src_list << '_multiprocessing/socket_connection.c' if major_ver == 2

    # build shared module
    module_name = '_multiprocessing'
    gen_module_android_mk "#{build_shared_dir}/jni/Android.mk", module_name, src_dir, src_list, module_type: :shared
    ndk_build build_shared_dir, abi
    FileUtils.cp "#{built_objs_dir(build_shared_dir, abi)}/lib#{module_name}.so", "#{pybin_install_shared_modules_dir}/#{module_name}.so"

    # build static module
    gen_module_android_mk "#{build_static_dir}/jni/Android.mk", static_module_name(module_name), src_dir, src_list, module_type: :static
    ndk_build build_static_dir, abi
    FileUtils.cp "#{built_objs_dir(build_static_dir, abi)}/lib#{static_module_name(module_name)}.a", pybin_install_static_libs_dir
    generate_python_module_header module_name
  end

  def build_module_socket(src_dir, build_dir, abi)
    base_dir = "#{build_dir}/socket"
    build_shared_dir = "#{base_dir}/shared"
    build_static_dir = "#{base_dir}/static"

    src_list = ['socketmodule.c']

    # build shared module
    module_name = '_socket'
    gen_module_android_mk "#{build_shared_dir}/jni/Android.mk", module_name, src_dir, src_list, module_type: :shared
    ndk_build build_shared_dir, abi
    FileUtils.cp "#{built_objs_dir(build_shared_dir, abi)}/lib#{module_name}.so", "#{pybin_install_shared_modules_dir}/#{module_name}.so"

    # build static module
    gen_module_android_mk "#{build_static_dir}/jni/Android.mk", static_module_name(module_name), src_dir, src_list, module_type: :static
    ndk_build build_static_dir, abi
    FileUtils.cp "#{built_objs_dir(build_static_dir, abi)}/lib#{static_module_name(module_name)}.a", pybin_install_static_libs_dir
    generate_python_module_header module_name
  end

  def build_module_ssl(src_dir, build_dir, abi, openssl_dir)
    base_dir = "#{build_dir}/ssl"
    build_shared_dir = "#{base_dir}/shared"
    build_static_dir = "#{base_dir}/static"

    src_list = ['_ssl.c']

    # build shared module
    module_name = '_ssl'
    options = { libraries:   ['libssl_shared', 'libcrypto_shared'],
                imports:     [openssl_dir],
                module_type: :shared
              }
    gen_module_android_mk "#{build_shared_dir}/jni/Android.mk", module_name, src_dir, src_list, options
    ndk_build build_shared_dir, abi
    FileUtils.cp "#{built_objs_dir(build_shared_dir, abi)}/lib#{module_name}.so", "#{pybin_install_shared_modules_dir}/#{module_name}.so"

    # build static module
    options[:libraries] = ['libssl_static', 'libcrypto_static']
    options[:module_type] = :static
    gen_module_android_mk "#{build_static_dir}/jni/Android.mk", static_module_name(module_name), src_dir, src_list, options
    ndk_build build_static_dir, abi
    FileUtils.cp "#{built_objs_dir(build_static_dir, abi)}/lib#{static_module_name(module_name)}.a", pybin_install_static_libs_dir
    generate_python_module_header module_name
  end

  def build_module_sqlite3(src_dir, build_dir, abi, sqlite_dir)
    base_dir = "#{build_dir}/sqlite3"
    build_shared_dir = "#{base_dir}/shared"
    build_static_dir = "#{base_dir}/static"

    src_list = ['cache.c',
                'connection.c',
                'cursor.c',
                'microprotocols.c',
                'module.c',
                'prepare_protocol.c',
                'row.c',
                'statement.c',
                'util.c'
               ].map { |f| "_sqlite/#{f}" }

    # build shared module
    module_name = '_sqlite3'
    options = { cflags:      ['-DMODULE_NAME=\"sqlite3\"'],
                libraries:   ['libsqlite3_shared'],
                imports:     [sqlite_dir],
                module_type: :shared
              }
    gen_module_android_mk "#{build_shared_dir}/jni/Android.mk", module_name, src_dir, src_list, options
    ndk_build build_shared_dir, abi
    FileUtils.cp "#{built_objs_dir(build_shared_dir, abi)}/lib#{module_name}.so", "#{pybin_install_shared_modules_dir}/#{module_name}.so"

    # build static module
    options[:libraries] = ['libsqlite3_static']
    options[:module_type] = :static
    gen_module_android_mk "#{build_static_dir}/jni/Android.mk", static_module_name(module_name), src_dir, src_list, options
    ndk_build build_static_dir, abi
    FileUtils.cp "#{built_objs_dir(build_static_dir, abi)}/lib#{static_module_name(module_name)}.a", pybin_install_static_libs_dir
    generate_python_module_header module_name
  end

  def build_module_pyexpat(src_dir, build_dir, abi)
    base_dir = "#{build_dir}/pyexpat"
    build_shared_dir = "#{base_dir}/shared"
    build_static_dir = "#{base_dir}/static"

    src_list = ['xmlparse.c', 'xmlrole.c', 'xmltok.c'].map { |f| "expat/#{f}" } + ['pyexpat.c']

    # build shared module
    module_name = 'pyexpat'
    options = { c_includes: ['$(MY_PYTHON_SRC_ROOT)/Modules/expat'],
                cflags: ['-DHAVE_EXPAT_CONFIG_H', '-DXML_STATIC'],
                module_type: :shared
              }
    gen_module_android_mk "#{build_shared_dir}/jni/Android.mk", module_name, src_dir, src_list, options
    ndk_build build_shared_dir, abi
    FileUtils.cp "#{built_objs_dir(build_shared_dir, abi)}/lib#{module_name}.so", "#{pybin_install_shared_modules_dir}/#{module_name}.so"

    # build static module
    options[:module_type] = :static
    gen_module_android_mk "#{build_static_dir}/jni/Android.mk", static_module_name(module_name), src_dir, src_list, options
    ndk_build build_static_dir, abi
    FileUtils.cp "#{built_objs_dir(build_static_dir, abi)}/lib#{static_module_name(module_name)}.a", pybin_install_static_libs_dir
    generate_python_module_header module_name
  end

  def build_module_select(src_dir, build_dir, abi)
    base_dir = "#{build_dir}/select"
    build_shared_dir = "#{base_dir}/shared"
    build_static_dir = "#{base_dir}/static"

    src_list = ['selectmodule.c']

    # build shared module
    module_name = 'select'
    gen_module_android_mk "#{build_shared_dir}/jni/Android.mk", module_name, src_dir, src_list, module_type: :shared
    ndk_build build_shared_dir, abi
    FileUtils.cp "#{built_objs_dir(build_shared_dir, abi)}/lib#{module_name}.so", "#{pybin_install_shared_modules_dir}/#{module_name}.so"

    # build static module
    gen_module_android_mk "#{build_static_dir}/jni/Android.mk", static_module_name(module_name), src_dir, src_list, module_type: :static
    ndk_build build_static_dir, abi
    FileUtils.cp "#{built_objs_dir(build_static_dir, abi)}/lib#{static_module_name(module_name)}.a", pybin_install_static_libs_dir
    generate_python_module_header module_name
  end

  def build_module_unicodedata(src_dir, build_dir, abi)
    base_dir = "#{build_dir}/unicodedata"
    build_shared_dir = "#{base_dir}/shared"
    build_static_dir = "#{base_dir}/static"

    src_list = ['unicodedata.c']

    # build shared module
    module_name = 'unicodedata'
    gen_module_android_mk "#{build_shared_dir}/jni/Android.mk", module_name, src_dir, src_list, module_type: :shared
    ndk_build build_shared_dir, abi
    FileUtils.cp "#{built_objs_dir(build_shared_dir, abi)}/lib#{module_name}.so", "#{pybin_install_shared_modules_dir}/#{module_name}.so"

    # build static module
    gen_module_android_mk "#{build_static_dir}/jni/Android.mk", static_module_name(module_name), src_dir, src_list, module_type: :static
    ndk_build build_static_dir, abi
    FileUtils.cp "#{built_objs_dir(build_static_dir, abi)}/lib#{static_module_name(module_name)}.a", pybin_install_static_libs_dir
    generate_python_module_header module_name
  end

  def gen_module_android_mk(filename, module_name, src_dir, file_list, options = {})
    options.default = []
    FileUtils.mkdir_p File.dirname(filename)
    File.open(filename, 'w') do |f|
      f.puts 'LOCAL_PATH := $(call my-dir)'
      f.puts 'include $(CLEAR_VARS)'
      f.puts "MY_PYTHON_SRC_ROOT := #{src_dir}"
      f.puts "LOCAL_MODULE := #{module_name}"
      #
      c_includes = install_include_dir
      options[:c_includes].each { |i| c_includes += ' ' + i }
      f.puts "LOCAL_C_INCLUDES :=#{c_includes}" if c_includes.size > 0
      #
      cflags = ''
      options[:cflags].each { |f| cflags += ' ' + f }
      f.puts "LOCAL_CFLAGS :=#{cflags}" if cflags.size > 0
      #
      f.puts 'LOCAL_SRC_FILES := \\'
      file_list.each do |file|
        cont = (file == file_list.last) ? '' : '  \\'
        f.puts "  $(MY_PYTHON_SRC_ROOT)/Modules/#{file}#{cont}"
      end
      #
      libs = ''
      options[:libraries].each { |l| libs += ' ' + l }
      case options[:module_type]
      when :shared
        f.puts 'LOCAL_SHARED_LIBRARIES := python_shared'
        f.puts "LOCAL_SHARED_LIBRARIES += #{libs}" if libs.size > 0
        f.puts 'include $(BUILD_SHARED_LIBRARY)'
      when :static
        f.puts "LOCAL_STATIC_LIBRARIES := #{libs}" if libs.size > 0
        f.puts 'include $(BUILD_STATIC_LIBRARY)'
      else
        raise "unsupport module type: #{options[:module_type]}"
      end
      #
      f.puts python_shared_section if options[:module_type] == :shared

      options[:imports].each { |im| f.puts "$(call import-module,#{im})" }
    end
  end

  def static_module_name(module_name)
    "python#{python_abi}_#{module_name}"
  end

  def python_module_header_name(module_name)
    "python_module_#{module_name}.h"
  end

  def generate_python_module_header(module_name)
    filename = File.join(install_frozen_include_dir, python_module_header_name(module_name))
    unless File.exist? filename
      File.open(filename, 'w') do |f|
        f.puts '#pragma once'
        f.puts ''
        if major_ver == 2
          f.puts "extern void init#{module_name}(void);"
        else
          f.puts '#include <Python.h>'
          f.puts ''
          f.puts "extern PyObject* PyInit_#{module_name}(void);"
        end
      end
    end
  end

  def gen_static_interpreter_android_mk(dir, abi, src_dir, openssl_dir, sqlite_dir)
    filename = File.join(dir, 'Android.mk')
    File.open(filename, 'w') do |f|
      f.puts 'LOCAL_PATH := $(call my-dir)'
      f.puts 'include $(CLEAR_VARS)'
      f.puts 'LOCAL_MODULE := python'
      f.puts ''
      f.puts "MY_PYTHON_SRC_ROOT := #{src_dir}"
      f.puts 'LOCAL_SRC_FILES := \\'
      f.puts '  interpreter.c python-stdlib.c \\'
      f.puts '  \\'
      f.puts '  ${MY_PYTHON_SRC_ROOT}/Modules/zlib/adler32.c  \\'
      f.puts '  ${MY_PYTHON_SRC_ROOT}/Modules/zlib/crc32.c    \\'
      f.puts '  ${MY_PYTHON_SRC_ROOT}/Modules/zlib/deflate.c  \\'
      f.puts '  ${MY_PYTHON_SRC_ROOT}/Modules/zlib/infback.c  \\'
      f.puts '  ${MY_PYTHON_SRC_ROOT}/Modules/zlib/inffast.c  \\'
      f.puts '  ${MY_PYTHON_SRC_ROOT}/Modules/zlib/inflate.c  \\'
      f.puts '  ${MY_PYTHON_SRC_ROOT}/Modules/zlib/inftrees.c \\'
      f.puts '  ${MY_PYTHON_SRC_ROOT}/Modules/zlib/trees.c    \\'
      f.puts '  ${MY_PYTHON_SRC_ROOT}/Modules/zlib/zutil.c'
      f.puts ''
      f.puts 'LOCAL_STATIC_LIBRARIES := \\'
      f.puts '  python_static                  \\'
      f.puts '  python_stdlib_static           \\'
      f.puts '  python_module__ctypes          \\'
      f.puts '  python_module__multiprocessing \\'
      f.puts '  python_module__socket          \\'
      f.puts '  python_module__ssl             \\'
      f.puts '  python_module__sqlite3         \\'
      f.puts '  python_module_pyexpat          \\'
      f.puts '  python_module_select           \\'
      f.puts '  python_module_unicodedata      \\'
      f.puts '  libsqlite3_static              \\'
      f.puts '  libssl_static                  \\'
      f.puts '  libcrypto_static'
      f.puts ''
      f.puts ''
      f.puts 'include $(BUILD_EXECUTABLE)'
      f.puts ''
      f.puts 'include $(CLEAR_VARS)'
      f.puts 'LOCAL_MODULE := python_static'
      f.puts "LOCAL_SRC_FILES := #{pybin_install_static_libs_dir}/libpython#{python_abi_as_lib_suffix}.a"
      f.puts "LOCAL_EXPORT_C_INCLUDES := #{install_include_dir}"
      f.puts 'include $(PREBUILT_STATIC_LIBRARY)'
      f.puts ''
      f.puts 'include $(CLEAR_VARS)'
      f.puts 'LOCAL_MODULE := python_stdlib_static'
      f.puts "LOCAL_SRC_FILES := #{pybin_install_static_libs_dir}/libpython#{python_abi}_stdlib.a"
      f.puts "LOCAL_EXPORT_C_INCLUDES := #{install_include_dir} #{install_frozen_include_dir}"
      f.puts 'include $(PREBUILT_STATIC_LIBRARY)'
      f.puts ''
      ['_ctypes', '_multiprocessing', '_socket', '_ssl', '_sqlite3', 'pyexpat', 'select', 'unicodedata'].each do |module_name|
        f.puts 'include $(CLEAR_VARS)'
        f.puts "LOCAL_MODULE := python_module_#{module_name}"
        f.puts "LOCAL_SRC_FILES := #{pybin_install_static_libs_dir}/libpython#{python_abi}_#{module_name}.a"
        f.puts "LOCAL_EXPORT_C_INCLUDES := #{install_include_dir} #{install_frozen_include_dir}"
        f.puts 'include $(PREBUILT_STATIC_LIBRARY)'
        f.puts ''
      end
      f.puts "$(call import-module,#{openssl_dir})"
      f.puts "$(call import-module,#{sqlite_dir})"
    end
  end

  def python_abi_as_lib_suffix
    (major_ver == 2) ? python_abi : "#{python_abi}m"
  end

  # take two last components of the path
  def import_module_path(path)
    v = path.split('/')
    "#{v[v.size-2]}/#{v[v.size-1]}"
  end

  def exe_platform(abi)
    case abi
    when 'x86', 'armeabi-v7a', 'armeabi-v7a-hard', 'mips'
      'android-16'
    when 'x86_64', 'arm64-v8a', 'mips64'
      'android-21'
    else
      raise "unsupported abi: #{abi}"
    end
  end

  def python_shared_section
    # could not use constant here since pybin_install_shared_libs_dir, etc
    # gets defined only in build_for_abi method
    "\n"                                                                                            +
    "include $(CLEAR_VARS)\n"                                                                       +
    "LOCAL_MODULE := python_shared\n"                                                               +
    "LOCAL_SRC_FILES := #{pybin_install_shared_libs_dir}/libpython#{python_abi_as_lib_suffix}.so\n" +
    "LOCAL_EXPORT_C_INCLUDES := #{install_include_dir}\n"                                           +
    "include $(PREBUILT_SHARED_LIBRARY)\n"
  end
end
