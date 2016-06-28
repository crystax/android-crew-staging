class Python < Package

  desc "Interpreted, interactive, object-oriented programming language"
  homepage "https://www.python.org"
  url "https://www.python.org/ftp/python/${version}/Python-${version}.tgz"

  release version: '2.7.11', crystax_version: 1, sha256: '0'
  release version: '3.5.1',  crystax_version: 1, sha256: '0'

  depends_on 'sqlite'

  build_copy 'LICENSE'
  build_options sysroot_in_cflags:  false,
                copy_incs_and_libs: false,
                gen_android_mk:     false

  def pre_build(src_dir, _release)
    build_dir = "#{build_base_dir}/native"
    FileUtils.mkdir_p build_dir
    FileUtils.cp_r "#{src_dir}/.", build_dir

    Build.gen_host_compiler_wrapper "#{build_dir}/gcc", 'gcc'
    Build.gen_host_compiler_wrapper "#{build_dir}/g++", 'g++'
    build_env['PATH'] = "#{build_dir}:#{ENV['PATH']}"

    FileUtils.cd(build_dir) do
      system './configure'
      system 'make', '-j', num_jobs
    end

    build_dir
  end

  def build_for_abi(abi, toolchain, release, dep_dirs)
    install_dir = install_dir_for_abi(abi)
    src_dir = build_dir_for_abi(abi)
    build_dir = "#{src_dir}/build"
    major_ver, python_abi = python_version_data(release)

    config_site = 'config.site'
    gen_config_site config_site, major_ver

    host_python = (Global::OS == 'darwin') ? 'python.exe' : 'python'

    build_env['CONFIG_SITE'] = config_site
    build_env['PYTHON_FOR_BUILD'] = "#{pre_build_result}/#{host_python}"
    build_env['PGEN_FOR_BUILD'] = "#{pre_build_result}/Parser/pgen"

    args = ["--prefix=#{install_dir}",
            "--host=#{host_for_abi(abi)}",
            "--build=#{python_build_platform}",
            "--enable-shared",
            "--with-threads",
            "--enable-ipv6",
            "--without-ensurepip"
           ]
    if major_ver == 2
      args << "--enable-unicode=ucs4"
    else
      args << "--with-computed-gotos"
    end

    system './configure', *args
    system 'make', '-j', num_jobs
    system 'make', 'install'
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

  # def post_build(pkg_dir, release)
  #   gen_android_mk pkg_dir, release
  # end

  # def build_for_abi(abi, toolchain, release, dep_dirs)

  #   # Step 2: build python-core
  #   # todo: use some dir inside crew repository for python support dir
  #   support_dir = "#{Global::NDK_DIR}/build/instruments/build-python"
  #   build_core_dir = "#{build_dir}/core"
  #   build_core_jni_dir = "#{build_core_dir}/jni"
  #   FileUtils.mkdir_p build_core_jni_dir
  #   pyconfig_abi_h = "pyconfig_#{abi.gsub('-', '_')}.h"
  #   FileUtils.cp "#{support_dir}/config.c.#{python_abi}",  "#{build_core_jni_dir}/config.c"
  #   FileUtils.cp "#{support_dir}/pyconfig.h",              "#{build_core_jni_dir}/"
  #   FileUtils.cp "#{support_dir}/getpath.c.#{python_abi}", "#{build_core_jni_dir}/getpath.c"         if major_ver == 2
  #   FileUtils.cp "#{config_dir}/pyconfig.h",               "#{build_core_jni_dir}/#{pyconfig_abi_h}"
  #   #
  #   gen_core_android_mk "#{build_core_jni_dir}/Android.mk", major_ver, python_abi, src_dir, support_dir
  #   ndk_build build_core_dir, abi
  #   #
  #   # copy common headers if they are not copied yet
  #   inc_dir = "#{package_dir}/include/python"
  #   if not Dir.exists? inc_dir
  #     FileUtils.mkdir_p inc_dir
  #     FileUtils.cp   "#{support_dir}/pyconfig.h", inc_dir
  #     FileUtils.cp_r "#{src_dir}/Include/.",      inc_dir
  #   end
  #   # copy abi specific config
  #   FileUtils.cp "#{build_core_jni_dir}/#{pyconfig_abi_h}", inc_dir
  #   # copy libs
  #   libs_dir = "#{package_dir}/libs/#{abi}"
  #   FileUtils.mkdir_p libs_dir
  #   # todo: while take lib from objs dir, not from libs dir?
  #   FileUtils.cp "#{built_objs_dir(build_core_dir, abi)}/lib#{python_core_module_name(major_ver, python_abi)}.so", libs_dir

  #   # Step 3: build python-interpreter
  #   build_interpreter_dir = "#{build_dir}/interpreter"
  #   build_interpreter_jni_dir = "#{build_interpreter_dir}/jni"
  #   FileUtils.mkdir_p build_interpreter_jni_dir
  #   FileUtils.cp "#{support_dir}/interpreter.c.#{python_abi}", "#{build_interpreter_jni_dir}/interpreter.c"
  #   #
  #   gen_interpreter_android_mk "#{build_interpreter_jni_dir}/Android.mk"
  #   ndk_build build_interpreter_dir, abi
  #   # copy interpreter
  #   bin_dir = "#{package_dir}/bin/#{abi}"
  #   FileUtils.mkdir_p bin_dir
  #   FileUtils.cp "#{built_objs_dir(build_interpreter_dir, abi)}/python", bin_dir

  #   # Step 4: build python stdlib
  #   stdlib_file = "#{libs_dir}/stdlib.zip"
  #   py2_flag = (major_ver == 2) ? '--py2' : ''
  #   system python_for_build, "#{support_dir}/build_stdlib.py", py2_flag, '--pysrc-root', src_dir, '--output-zip', stdlib_file

  #   # Step 5: site-packages
  #   site_dir = "#{libs_dir}/site-packages"
  #   FileUtils.mkdir_p site_dir
  #   FileUtils.cp "#{src_dir}/Lib/site-packages/README", site_dir

  #   # Step 6: build python modules
  #   modules_install_dir = "#{libs_dir}/modules"
  #   FileUtils.mkdir_p modules_install_dir
  #   sqlite_dir = import_module_path(dep_dirs['sqlite'])
  #   #
  #   build_module_ctypes          src_dir, build_dir, modules_install_dir, abi, python_abi
  #   build_module_multiprocessing src_dir, build_dir, modules_install_dir, abi, python_abi, major_ver
  #   build_module_socket          src_dir, build_dir, modules_install_dir, abi, python_abi
  #   build_module_sqlite3         src_dir, build_dir, modules_install_dir, abi, python_abi, sqlite_dir
  #   build_module_pyexpat         src_dir, build_dir, modules_install_dir, abi, python_abi
  #   build_module_select          src_dir, build_dir, modules_install_dir, abi, python_abi
  #   build_module_unicodedata     src_dir, build_dir, modules_install_dir, abi, python_abi
  # end

  # def python_core_module_name(major_ver, python_abi)
  #   major_ver == 2 ? "python#{python_abi}"  : "python#{python_abi}m"
  # end

  # def gen_core_android_mk(filename, major_ver, python_abi, src_dir, support_dir)
  #   local_cflags  = '-DPy_BUILD_CORE -DPy_ENABLE_SHARED -DPLATFORM="linux"'
  #   local_cflags += " -DSOABI=\\\"cpython-#{python_abi}m\\\"" if major_ver > 2

  #   File.open(filename, 'w') do |f|
  #     f.puts 'LOCAL_PATH := $(call my-dir)'
  #     f.puts 'include $(CLEAR_VARS)'
  #     f.puts "LOCAL_MODULE := #{python_core_module_name(major_ver, python_abi)}"
  #     f.puts "MY_PYTHON_SRC_ROOT := #{src_dir}"
  #     f.puts 'LOCAL_C_INCLUDES := $(MY_PYTHON_SRC_ROOT)/Include'
  #     f.puts "LOCAL_CFLAGS := #{local_cflags}"
  #     f.puts 'LOCAL_LDLIBS := -lz'
  #     f.puts File.read("#{support_dir}/android.mk.#{python_abi}")
  #     f.puts 'include $(BUILD_SHARED_LIBRARY)'
  #   end
  # end

  # def gen_interpreter_android_mk(filename)
  #   File.open(filename, 'w') do |f|
  #     f.puts 'LOCAL_PATH := $(call my-dir)'
  #     f.puts 'include $(CLEAR_VARS)'
  #     f.puts 'LOCAL_MODULE := python'
  #     f.puts 'LOCAL_SRC_FILES := interpreter.c'
  #     f.puts 'include $(BUILD_EXECUTABLE)'
  #   end
  # end

  # def build_module_ctypes(src_dir, build_dir, install_dir, abi, python_abi)
  #   build_ctypes_dir = "#{build_dir}/ctypes"
  #   config_dir = "#{build_ctypes_dir}/config"
  #   FileUtils.mkdir_p config_dir

  #   args = ["--host=#{host_for_abi(abi)}",
  #           "--build=#{python_build_platform}",
  #           "--prefix=#{build_ctypes_dir}/install"
  #          ]
  #   FileUtils.cd(config_dir) { system "#{src_dir}/Modules/_ctypes/libffi/configure", *args }

  #   jni_dir = "#{build_ctypes_dir}/jni"
  #   inc_dir = "#{jni_dir}/include"
  #   FileUtils.mkdir_p inc_dir

  #   FileUtils.cp "#{config_dir}/fficonfig.h",      inc_dir
  #   FileUtils.cp Dir["#{config_dir}/include/*.h"], inc_dir

  #   src_list = ffi_src_list(abi).map { |f| "_ctypes/libffi/#{f}" } +
  #              [ 'callbacks.c', 'callproc.c', 'cfield.c', 'malloc_closure.c', 'stgdict.c', '_ctypes.c'].map { |f| "_ctypes/#{f}" }

  #   gen_module_android_mk "#{jni_dir}/Android.mk", '_ctypes', src_dir, src_list, python_abi, { c_includes: ['$(LOCAL_PATH)/include'] }
  #   ndk_build build_ctypes_dir,abi

  #   FileUtils.cp "#{built_objs_dir(build_ctypes_dir, abi)}/lib_ctypes.so", "#{install_dir}/_ctypes.so"
  # end

  # def ffi_src_list(abi)
  #   src = ['src/prep_cif.c']
  #   case abi
  #   when 'x86'       then src += ['src/x86/ffi.c', 'src/x86/sysv.S', 'src/x86/win32.S']
  #   when 'x86_64'    then src += ['src/x86/ffi64.c', 'src/x86/unix64.S']
  #   when /^armeabi/  then src += ['src/arm/ffi.c', 'src/arm/sysv.S']
  #   when 'arm64-v8a' then src += ['src/aarch64/ffi.c', 'src/aarch64/sysv.S']
  #   when 'mips'      then src += ['src/mips/ffi.c', 'src/mips/o32.S']
  #   when 'mips64'    then src += ['src/mips/ffi.c', 'src/mips/o32.S', 'src/mips/n32.S']
  #   else
  #     raise "unknown ABI #{abi}"
  #   end
  #   src
  # end

  # def build_module_multiprocessing(src_dir, build_dir, install_dir, abi, python_abi, major_ver)
  #   build_multiprocessing_dir = "#{build_dir}/multiprocessing"
  #   jni_dir = "#{build_multiprocessing_dir}/jni"
  #   FileUtils.mkdir_p jni_dir

  #   src_list = ['_multiprocessing/multiprocessing.c', '_multiprocessing/semaphore.c']
  #   src_list << '_multiprocessing/socket_connection.c' if major_ver == 2

  #   gen_module_android_mk "#{jni_dir}/Android.mk", '_multiprocessing', src_dir, src_list, python_abi
  #   ndk_build build_multiprocessing_dir, abi

  #   FileUtils.cp "#{built_objs_dir(build_multiprocessing_dir, abi)}/lib_multiprocessing.so", "#{install_dir}/_multiprocessing.so"
  # end

  # def build_module_socket(src_dir, build_dir, install_dir, abi, python_abi)
  #   build_socket_dir = "#{build_dir}/socket"
  #   jni_dir = "#{build_socket_dir}/jni"
  #   FileUtils.mkdir_p jni_dir

  #   gen_module_android_mk "#{jni_dir}/Android.mk", '_socket', src_dir, ['socketmodule.c'], python_abi
  #   ndk_build build_socket_dir, abi

  #   FileUtils.cp "#{built_objs_dir(build_socket_dir, abi)}/lib_socket.so", "#{install_dir}/_socket.so"
  # end

  # def build_module_sqlite3(src_dir, build_dir, install_dir, abi, python_abi, sqlite_dir)
  #   build_sqlite_dir = "#{build_dir}/sqlite3"
  #   jni_dir = "#{build_sqlite_dir}/jni"
  #   FileUtils.mkdir_p jni_dir

  #   src_list = ['cache.c',
  #               'connection.c',
  #               'cursor.c',
  #               'microprotocols.c',
  #               'module.c',
  #               'prepare_protocol.c',
  #               'row.c',
  #               'statement.c',
  #               'util.c'
  #              ].map { |f| "_sqlite/#{f}" }

  #   options = { cflags:           ['-DMODULE_NAME=\"sqlite3\"'],
  #               static_libraries: ['libsqlite3_static'],         # todo: rename module
  #               imports:          [sqlite_dir]
  #             }
  #   gen_module_android_mk "#{jni_dir}/Android.mk", '_sqlite3', src_dir, src_list, python_abi, options
  #   ndk_build build_sqlite_dir, abi

  #   FileUtils.cp "#{built_objs_dir(build_sqlite_dir, abi)}/lib_sqlite3.so", "#{install_dir}/_sqlite3.so"
  # end

  # def build_module_pyexpat(src_dir, build_dir, install_dir, abi, python_abi)
  #   build_pyexpat_dir = "#{build_dir}/pyexpat"
  #   jni_dir = "#{build_pyexpat_dir}/jni"
  #   FileUtils.mkdir_p jni_dir

  #   src_list = ['xmlparse.c', 'xmlrole.c', 'xmltok.c'].map { |f| "expat/#{f}" } + ['pyexpat.c']
  #   options = { c_includes: ['$(MY_PYTHON_SRC_ROOT)/Modules/expat'],
  #               cflags: ['-DHAVE_EXPAT_CONFIG_H', '-DXML_STATIC']
  #             }
  #   gen_module_android_mk "#{jni_dir}/Android.mk", 'pyexpat', src_dir, src_list, python_abi, options
  #   ndk_build build_pyexpat_dir, abi

  #   FileUtils.cp "#{built_objs_dir(build_pyexpat_dir, abi)}/libpyexpat.so", "#{install_dir}/pyexpat.so"
  # end

  # def build_module_select(src_dir, build_dir, install_dir, abi, python_abi)
  #   build_select_dir = "#{build_dir}/select"
  #   jni_dir = "#{build_select_dir}/jni"
  #   FileUtils.mkdir_p jni_dir

  #   gen_module_android_mk "#{jni_dir}/Android.mk", 'select', src_dir, ['selectmodule.c'], python_abi
  #   ndk_build build_select_dir, abi

  #   FileUtils.cp "#{built_objs_dir(build_select_dir, abi)}/libselect.so", "#{install_dir}/select.so"
  # end

  # def build_module_unicodedata(src_dir, build_dir, install_dir, abi, python_abi)
  #   build_unicodedata_dir = "#{build_dir}/unicodedata"
  #   jni_dir = "#{build_unicodedata_dir}/jni"
  #   FileUtils.mkdir_p jni_dir

  #   gen_module_android_mk "#{jni_dir}/Android.mk", 'unicodedata', src_dir, ['unicodedata.c'], python_abi
  #   ndk_build build_unicodedata_dir, abi

  #   FileUtils.cp "#{built_objs_dir(build_unicodedata_dir, abi)}/libunicodedata.so", "#{install_dir}/unicodedata.so"
  # end

  # def gen_module_android_mk(filename, module_name, src_dir, file_list, python_abi, options = {})
  #   options.default = []
  #   File.open(filename, 'w') do |f|
  #     f.puts 'LOCAL_PATH := $(call my-dir)'
  #     f.puts 'include $(CLEAR_VARS)'
  #     f.puts "MY_PYTHON_SRC_ROOT := #{src_dir}"
  #     f.puts "LOCAL_MODULE := #{module_name}"
  #     #
  #     c_includes = ''
  #     options[:c_includes].each { |i| c_includes += ' ' + i }
  #     f.puts "LOCAL_C_INCLUDES :=#{c_includes}" if c_includes.size > 0
  #     #
  #     cflags = ''
  #     options[:cflags].each { |f| cflags += ' ' + f }
  #     f.puts "LOCAL_CFLAGS :=#{cflags}" if cflags.size > 0
  #     #
  #     f.puts 'LOCAL_SRC_FILES := \\'
  #     file_list.each do |file|
  #       cont = (file == file_list.last) ? '' : '  \\'
  #       f.puts "  $(MY_PYTHON_SRC_ROOT)/Modules/#{file}#{cont}"
  #     end
  #     #
  #     libs = 'LOCAL_STATIC_LIBRARIES := python_shared'
  #     options[:static_libraries].each { |l| libs += ' ' + l }
  #     f.puts libs
  #     #
  #     f.puts 'include $(BUILD_SHARED_LIBRARY)'
  #     f.puts "$(call import-module,python/#{python_abi})"
  #     #
  #     options[:imports].each { |im| f.puts "$(call import-module,#{im})" }
  #   end
  # end

  # def ndk_build(build_dir, abi)
  #   system "#{Global::NDK_DIR}/ndk-build", '-C', build_dir, "-j#{num_jobs}", "APP_ABI=#{abi}", 'V=1'
  # end

  # def built_objs_dir(build_dir, abi)
  #   "#{build_dir}/obj/local/#{abi}"
  # end

  # # take two last components of the path
  # def import_module_path(path)
  #   v = path.split('/')
  #   "#{v[v.size-2]}/#{v[v.size-1]}"
  # end

  # def gen_android_mk(pkg_dir, release)
  #   v = release.version.split('.')
  #   vs = v[0] +'.' + v[1]
  #   vs += 'm' if (v[0].to_i > 2)
  #   File.open("#{pkg_dir}/Android.mk", "w") do |f|
  #     f.puts Build::COPYRIGHT_STR
  #     f.puts ''
  #     f.puts 'LOCAL_PATH := $(call my-dir)'
  #     f.puts ''
  #     f.puts 'include $(CLEAR_VARS)'
  #     f.puts 'LOCAL_MODULE := python_shared'
  #     f.puts "LOCAL_SRC_FILES := libs/$(TARGET_ARCH_ABI)/libpython#{vs}.so"
  #     f.puts 'LOCAL_EXPORT_C_INCLUDES := $(LOCAL_PATH)/include/python'
  #     f.puts 'include $(PREBUILT_SHARED_LIBRARY)'
  #   end
  # end
end
