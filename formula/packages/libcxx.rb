class Libcxx < BasePackage

  desc "LLVM Standard C++ Library"
  name 'libc++'

  release '3.6', crystax: 6
  release '3.7', crystax: 6
  release '3.8', crystax: 6

  build_depends_on 'platforms'
  build_depends_on 'libcrystax'
  # todo:
  #build_depends_on default_gcc_compiler

  def release_directory(release, _platform_name = nil)
    "#{Global::NDK_DIR}/#{archive_sub_dir(release)}"
  end

  def remove_installed_files(release)
    FileUtils.rm_rf release_directory(release)
  end

  def build(release, options, _host_dep_dirs, target_dep_info)
    arch_list = Build.abis_to_arch_list(options.abis)
    puts "Building #{name} #{release} for architectures: #{arch_list.map{|a| a.name}.join(' ')}"

    base_dir = build_base_dir
    FileUtils.rm_rf base_dir

    @log_file = build_log_file
    @num_jobs = options.num_jobs

    parse_target_dep_info target_dep_info

    toolchain = select_llvm(release.version)

    FileUtils.mkdir_p package_dir
    arch_list.each do |arch|
      puts "= building for architecture: #{arch.name}"
      arch_build_dir = File.join(build_base_dir, arch.name)
      arch.abis_to_build.each do |abi|
        puts "  building for abi: #{abi}"
        build_dir = File.join(arch_build_dir, abi, 'build')
        FileUtils.mkdir_p build_dir
        FileUtils.cd(build_dir) do
          [:static, :shared].each { |lt| build_for_abi abi, toolchain, release, package_dir, lib_type: lt }
          [:static, :shared].each { |lt| build_for_abi abi, toolchain, release, package_dir, lib_type: lt, thumb: true } if arch.name == 'arm'
        end
      end
      FileUtils.rm_rf arch_build_dir unless options.no_clean?
      # copy sources
      llvm_dir = "#{Build::TOOLCHAIN_SRC_DIR}/llvm-#{release.version}"
      cxx_src_out_dir    = "#{package_dir}/#{archive_sub_dir(release)}/libcxx"
      cxxabi_src_out_dir = "#{package_dir}/#{archive_sub_dir(release)}/libcxxabi"
      FileUtils.mkdir_p [cxx_src_out_dir, cxxabi_src_out_dir]
      FileUtils.cp_r ['include', 'src', 'test'].map{ |d| "#{llvm_dir}/libcxx/#{d}" },    "#{cxx_src_out_dir}/"
      FileUtils.cp_r ['include', 'src', 'test'].map{ |d| "#{llvm_dir}/libcxxabi/#{d}" }, "#{cxxabi_src_out_dir}/"
    end

    write_build_info release, package_dir

    if options.build_only?
      puts "Build only, no packaging and installing"
    else
      archive = cache_file(release)
      puts "Creating archive file #{archive}"
      Utils.pack(archive, package_dir)
      clean_deb_cache release, options.abis

      install_archive release, archive if options.install?
    end

    update_shasum release if options.update_shasum?

    if options.no_clean?
      puts "No cleanup, for build artifacts see #{base_dir}"
    else
      FileUtils.rm_rf base_dir
    end
  end

  def copy_to_standalone_toolchain(release, arch, target_include_dir, target_lib_dir, options)
    make_target_lib_dirs(arch, target_lib_dir)

    release_dir = archive_sub_dir(release)

    cxx_include_dir = "#{target_include_dir}/c++/#{options[:gcc_version]}"
    cxxabi_include_dir = "#{target_include_dir}/llvm-libc++abi"
    FileUtils.mkdir_p [cxx_include_dir, cxxabi_include_dir]

    # copy headers
    FileUtils.cp_r Dir["#{release_dir}/libcxx/include/*"],    cxx_include_dir
    FileUtils.cp_r Dir["#{release_dir}/libcxxabi/include/*"], cxx_include_dir
    FileUtils.cp_r Dir["#{release_dir}/libcxxabi/include/*"], cxxabi_include_dir
    # todo: these files are present only in cxxabi 3.6
    #FileUtils.cp ['cxxabi.h', 'libunwind.h', 'unwind.h'].map { |f| "#{cxxabi_include_dir}/#{f}" }, cxx_include_dir

    # copy libs
    case arch.name
    when 'arm'
      # todo: ?
      FileUtils.cp "#{release_dir}/libs/armeabi-v7a/libc++_shared.so",       "#{target_lib_dir}/lib/libc++_shared.so"
      FileUtils.cp "#{release_dir}/libs/armeabi-v7a/libc++_static.a",        "#{target_lib_dir}/lib/libstdc++.a"
      FileUtils.cp "#{release_dir}/libs/armeabi-v7a/thumb/libc++_shared.so", "#{target_lib_dir}/lib/thumb/libc++_shared.so"
      FileUtils.cp "#{release_dir}/libs/armeabi-v7a/thumb/libc++_static.a",  "#{target_lib_dir}/lib/thumb/libstdc++.a"
      #
      FileUtils.cp "#{release_dir}/libs/armeabi-v7a/libc++_shared.so",       "#{target_lib_dir}/lib/armv7-a/libc++_shared.so"
      FileUtils.cp "#{release_dir}/libs/armeabi-v7a/libc++_static.a",        "#{target_lib_dir}/lib/armv7-a/libstdc++.a"
      FileUtils.cp "#{release_dir}/libs/armeabi-v7a/thumb/libc++_shared.so", "#{target_lib_dir}/lib/armv7-a/thumb/libc++_shared.so"
      FileUtils.cp "#{release_dir}/libs/armeabi-v7a/thumb/libc++_static.a",  "#{target_lib_dir}/lib/armv7-a/thumb/libstdc++.a"
      #
      FileUtils.cp "#{release_dir}/libs/armeabi-v7a-hard/libc++_shared.so",       "#{target_lib_dir}/lib/armv7-a/hard/libc++_shared.so"
      FileUtils.cp "#{release_dir}/libs/armeabi-v7a-hard/libc++_static.a",        "#{target_lib_dir}/lib/armv7-a/hard/libstdc++.a"
      FileUtils.cp "#{release_dir}/libs/armeabi-v7a-hard/thumb/libc++_shared.so", "#{target_lib_dir}/lib/armv7-a/thumb/hard/libc++_shared.so"
      FileUtils.cp "#{release_dir}/libs/armeabi-v7a-hard/thumb/libc++_static.a",  "#{target_lib_dir}/lib/armv7-a/thumb/hard/libstdc++.a"
    when 'x86_64'
      FileUtils.cp "#{release_dir}/libs/x86_64/libc++_shared.so", "#{target_lib_dir}/lib64/libc++_shared.so"
      FileUtils.cp "#{release_dir}/libs/x86_64/libc++_static.a",  "#{target_lib_dir}/lib64/libstdc++.a"
    else
      FileUtils.cp "#{release_dir}/libs/#{arch.abis[0]}/libc++_shared.so", "#{target_lib_dir}/lib/libc++_shared.so"
      FileUtils.cp "#{release_dir}/libs/#{arch.abis[0]}/libc++_static.a",  "#{target_lib_dir}/lib/libstdc++.a"
    end
  end

  def build_for_abi(abi, toolchain, release, install_dir, options)
    build_dir = options[:lib_type].to_s
    build_dir += '_thumb' if options[:thumb]

    FileUtils.mkdir build_dir
    FileUtils.cd(build_dir) do
      generate_makefile abi, toolchain, release, install_dir, options
      system 'make', '-j', num_jobs
    end
  end

  def generate_makefile(abi, toolchain, release, install_dir, options)
    llvm_dir = "#{Build::TOOLCHAIN_SRC_DIR}/llvm-#{release.version}"
    out_dir = "#{install_dir}/#{lib_dir(abi, release, options)}"
    FileUtils.mkdir_p out_dir

    arch = Build.arch_for_abi(abi)

    cc = toolchain.c_compiler(arch, abi)
    cxx = toolchain.cxx_compiler(arch, abi)
    ar = toolchain.tool(arch, 'ar')

    lib_file = "#{out_dir}/libc++_" + (options[:lib_type] == :static ? 'static.a' : 'shared.so')

    src_files = source_files(abi, release)
    obj_dirs = src_files.map {|f| File.dirname f}.sort.uniq
    obj_files = src_files.map {|f| src_to_obj f }

    c_flags, cxx_flags, ld_flags = build_flags(abi, toolchain, llvm_dir, options)
    ar_flags = 'crsD'

    crtbegin_so, crtend_so = crt_files(abi)

    File.open('Makefile', 'w') do |f|
      f.puts '# Auto-generated - do not edit!'
      f.puts '.PHONY: all dirs'
      f.puts
      f.puts "CC  = #{cc}"
      f.puts "CXX = #{cxx}"
      f.puts "AR  = #{ar}"
      f.puts
      f.puts "CFLAGS   = #{c_flags}"
      f.puts "CXXFLAGS = #{cxx_flags}"
      f.puts "LDFLAGS  = #{ld_flags}"
      f.puts "ARFLAGS  = #{ar_flags}"
      f.puts
      f.puts "all: dirs #{lib_file}"
      f.puts
      f.puts 'dirs:'
      f.puts "\tmkdir -p #{obj_dirs.join(' ')}"
      f.puts
      f.puts "#{lib_file}: #{obj_files.join(' ')}"
      if options[:lib_type] == :static
        f.puts "\t$(AR) $(ARFLAGS) $@ #{obj_files.join(' ')}"
      else
        f.puts "\t$(CXX) $(LDFLAGS) -o $@ #{crtbegin_so} #{obj_files.join(' ')} -lgcc #{crtend_so}"
      end
      f.puts
      src_files.each do |src|
        ext = File.extname(src)
        obj = src_to_obj(src)
        f.puts "#{obj}: #{llvm_dir}/#{src}"
        case ext
        when '.cpp'
          f.puts "\t$(CXX) -c -o $@ $(CXXFLAGS) #{llvm_dir}/#{src}"
        when '.c', '.S', '.s'
          f.puts "\t$(CC) -c -o $@ $(CFLAGS) #{llvm_dir}/#{src}"
        else
          raise "unsupported file type: #{src}"
        end
        f.puts
      end
    end
  end

  def src_to_obj(src)
    base = File.basename(src, File.extname(src))
    "#{File.dirname(src)}/#{base}.o"
  end

  def select_llvm(ver)
    case ver
    when '3.6' then Toolchain::LLVM_3_6
    when '3.7' then Toolchain::LLVM_3_7
    when '3.8' then Toolchain::LLVM_3_8
    else
      raise "no LLVM version for libc++ version: #{version}"
    end
  end

  def source_files(abi, release)
    libcxx =
      ["libcxx/src/algorithm.cpp",
       "libcxx/src/bind.cpp",
       "libcxx/src/chrono.cpp",
       "libcxx/src/condition_variable.cpp",
       "libcxx/src/debug.cpp",
       "libcxx/src/exception.cpp",
       "libcxx/src/future.cpp",
       "libcxx/src/hash.cpp",
       "libcxx/src/ios.cpp",
       "libcxx/src/iostream.cpp",
       "libcxx/src/locale.cpp",
       "libcxx/src/memory.cpp",
       "libcxx/src/mutex.cpp",
       "libcxx/src/new.cpp",
       "libcxx/src/optional.cpp",
       "libcxx/src/random.cpp",
       "libcxx/src/regex.cpp",
       "libcxx/src/shared_mutex.cpp",
       "libcxx/src/stdexcept.cpp",
       "libcxx/src/string.cpp",
       "libcxx/src/strstream.cpp",
       "libcxx/src/system_error.cpp",
       "libcxx/src/thread.cpp",
       "libcxx/src/typeinfo.cpp",
       "libcxx/src/utility.cpp",
       "libcxx/src/valarray.cpp"
      ]

    libcxxabi =
      ["libcxxabi/src/abort_message.cpp",
       "libcxxabi/src/cxa_aux_runtime.cpp",
       "libcxxabi/src/cxa_default_handlers.cpp",
       "libcxxabi/src/cxa_demangle.cpp",
       "libcxxabi/src/cxa_exception.cpp",
       "libcxxabi/src/cxa_exception_storage.cpp",
       "libcxxabi/src/cxa_guard.cpp",
       "libcxxabi/src/cxa_handlers.cpp",
       "libcxxabi/src/cxa_new_delete.cpp",
       "libcxxabi/src/cxa_personality.cpp",
       "libcxxabi/src/cxa_thread_atexit.cpp",
       "libcxxabi/src/cxa_unexpected.cpp",
       "libcxxabi/src/cxa_vector.cpp",
       "libcxxabi/src/cxa_virtual.cpp",
       "libcxxabi/src/exception.cpp",
       "libcxxabi/src/private_typeinfo.cpp",
       "libcxxabi/src/stdexcept.cpp",
       "libcxxabi/src/typeinfo.cpp"
      ]

    libcxxabi_unwind =
      ["libcxxabi/src/Unwind/libunwind.cpp",
       "libcxxabi/src/Unwind/Unwind-EHABI.cpp",
       "libcxxabi/src/Unwind/Unwind-sjlj.c",
       "libcxxabi/src/Unwind/UnwindLevel1.c",
       "libcxxabi/src/Unwind/UnwindLevel1-gcc-ext.c",
       "libcxxabi/src/Unwind/UnwindRegistersRestore.S",
       "libcxxabi/src/Unwind/UnwindRegistersSave.S"
      ]

    src = libcxx + libcxxabi
    src += libcxxabi_unwind if release.version == '3.6' and abi =~ /armeabi/

    src
  end

  def lib_dir(abi, release, options)
    dir  = "#{archive_sub_dir(release)}/libs/#{abi}"
    dir += "/thumb" if options[:thumb]
    dir
  end

  def crt_files(abi)
    arch = Build.arch_for_abi(abi)
    lib_dir = "#{Build.sysroot(abi)}/usr/#{arch.default_lib_dir}"
    ["#{lib_dir}/crtbegin_so.o", "#{lib_dir}/crtend_so.o"]
  end

  def build_flags(abi, toolchain, llvm_dir, options)
    c_flags = " --sysroot=#{Build.sysroot(abi)} -fno-integrated-as -funwind-tables"
    ld_flags = "--sysroot=#{Build.sysroot(abi)} -nostdlib -Wl,-soname,libc++_shared.so -Wl,-shared"

    case abi
    when 'armeabi-v7a'
      c_flags  += ' -march=armv7-a -mfpu=vfpv3-d16 -mfloat-abi=softfp'
      ld_flags += ' -Wl,--fix-cortex-a8'
    when 'armeabi-v7a-hard'
      c_flags  += ' -march=armv7-a -mfpu=vfpv3-d16 -mhard-float -D_NDK_MATH_NO_SOFTFP=1'
      ld_flags += ' -Wl,--fix-cortex-a8 -Wl,--no-warn-mismatch -lm_hard'
    when 'x86', 'x86_64'
      # ToDo: remove the following once all x86-based device call JNI function with
      #       stack aligned to 16-byte
      c_flags += ' -mstackrealign'
    end

    cxx_flags = c_flags

    libcxx_src = "#{llvm_dir}/libcxx"
    libcxxabi_src = "#{llvm_dir}/libcxxabi"
    crystax_src = "#{Global::NDK_DIR}/sources/crystax"
    libcxx_includes = "-I#{libcxx_src}/include -I#{libcxxabi_src}/include -I#{crystax_src}/include"

    common_c_cxx_flags = "-fPIC -O2 -ffunction-sections -fdata-sections -g"
    common_cxxflags    = "-fexceptions -frtti -fuse-cxa-atexit" # todo: the flags were never used in build scripts

    libcxx_cflags   = common_c_cxx_flags + ' ' + libcxx_includes + ' -Drestrict=__restrict__'
    libcxx_cxxflags = libcxx_cflags +
                      ' -DLIBCXXABI=1 -std=c++11 -D__STDC_FORMAT_MACROS' +
                      ' -Wall -Wextra -Wno-unused-parameter -Wno-unused-variable -Wno-unused-function -Werror'

    crystax_lib = "#{crystax_src}/libs/#{abi}" + (options[:thumb] ? '/thumb' : '')
    libcxx_ldflags = "-L#{crystax_lib}"
    libcxx_linker_script = "#{Global::NDK_DIR}/sources/cxx-stl/llvm-libc++/export_symbols.txt"
    if File.exist? libcxx_linker_script
      libcxx_ldflags += " -Wl,--version-script,#{libcxx_linker_script}"
    end

    cxx_flags += " -DLIBCXXABI_USE_LLVM_UNWINDER=#{abi =~ /armeabi/ ? 1 : 0}"

    if options[:thumb]
        c_flags += " -mthumb"
        cxx_flags += " -mthumb"
    end

    c_flags   += ' -fvisibility=hidden -fvisibility-inlines-hidden'
    cxx_flags += ' -fvisibility=hidden -fvisibility-inlines-hidden' unless options[:lib_type] == :shared

    c_flags   += ' ' + libcxx_cflags
    cxx_flags += ' ' + libcxx_cxxflags
    ld_flags  += ' ' + libcxx_ldflags + ' -ldl'


    [c_flags, cxx_flags, ld_flags]
  end

  def package_dir
    "#{build_base_dir}/package"
  end

  def archive_sub_dir(release)
    "sources/cxx-stl/llvm-libc++/#{release.version}"
  end
end
