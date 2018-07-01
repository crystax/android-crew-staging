class Libstdcxx < BasePackage

  desc "GNU Standard C++ Library"
  name 'libstdc++'
  # todo:
  #homepage ""
  #url ""

  release '4.9', crystax: 4
  release '5',   crystax: 4
  release '6',   crystax: 4

  build_depends_on 'platforms'
  build_depends_on 'libcrystax'
  # todo:
  #build_depends_on default_gcc_compiler

  # todo: move method to the BasePackage class?
  def install_archive(release, archive, _platform_name = nil)
    prop_dir = properties_directory(release)
    FileUtils.mkdir_p prop_dir unless Dir.exists? prop_dir
    prop = get_properties(prop_dir)

    FileUtils.rm_rf "#{Global::NDK_DIR}/#{archive_sub_dir(release)}"
    puts "Unpacking archive into #{Global::NDK_DIR}/#{archive_sub_dir(release)}"
    Utils.unpack archive, Global::NDK_DIR

    prop[:installed] = true
    prop[:installed_crystax_version] = release.crystax_version
    save_properties prop, prop_dir

    release.installed = release.crystax_version
  end

  def uninstall(release)
    puts "removing #{name}:#{release.version}"

    FileUtils.rm_rf "#{Global::NDK_DIR}/#{archive_sub_dir(release)}"

    prop_dir = properties_directory(release)
    prop = get_properties(prop_dir)
    prop[:installed] = false
    prop.delete :installed_crystax_version
    save_properties prop, prop_dir

    release.installed = false
  end

  def build(release, options, _host_dep_dirs, _target_dep_dirs)
    arch_list = Build.abis_to_arch_list(options.abis)
    puts "Building #{name} #{release} for architectures: #{arch_list.map{|a| a.name}.join(' ')}"

    base_dir = build_base_dir
    FileUtils.rm_rf base_dir
    @log_file = build_log_file
    @num_jobs = options.num_jobs

    toolchain = select_gcc(release.version)

    FileUtils.mkdir_p package_dir
    arch_list.each do |arch|
      puts "= building for architecture: #{arch.name}"
      arch_build_dir = File.join(build_base_dir, arch.name)
      sysroot = File.join(arch_build_dir, 'sysroot')
      puts "  copying sysroot into #{sysroot}"
      copy_sysroot arch, sysroot
      arch.abis_to_build.each do |abi|
        puts "  building for abi: #{abi}"
        build_dir = File.join(arch_build_dir, abi, 'build')
        install_dir = File.join(arch_build_dir, abi, 'install')
        FileUtils.mkdir_p build_dir
        FileUtils.cd(build_dir) do
          [:static, :shared].each { |lt| build_for_abi abi, toolchain, release, sysroot, install_dir, lib_type: lt }
          [:static, :shared].each { |lt| build_for_abi abi, toolchain, release, sysroot, install_dir, lib_type: lt, thumb: true } if arch.name == 'arm'
        end
        copy_installed_files abi, release, install_dir
      end
      FileUtils.rm_rf arch_build_dir unless options.no_clean?
    end

    if options.build_only?
      puts "Build only, no packaging and installing"
    else
      archive = cache_file(release)
      puts "Creating archive file #{archive}"
      Utils.pack(archive, package_dir)

      install_archive release, archive if options.install?
    end

    update_shasum release if options.update_shasum?

    if options.no_clean?
      puts "No cleanup, for build artifacts see #{base_dir}"
    else
      FileUtils.rm_rf base_dir
    end
  end

  def copy_to_standalone_toolchain(release, arch, target_include_dir, target_lib_dir, _options)
    make_target_lib_dirs(arch, target_lib_dir)

    release_dir = archive_sub_dir(release)

    include_dir = "#{target_include_dir}/c++/#{release.version}"
    arch_include_dir = "#{include_dir}/#{arch.host}"
    FileUtils.mkdir_p arch_include_dir

    # copy common headers
    FileUtils.cp_r Dir["#{release_dir}/include/*"], include_dir

    # copy arch/abi specific libs and headers
    case arch.name
    when 'arm'
      # todo: ?
      FileUtils.cp "#{release_dir}/libs/armeabi-v7a/libgnustl_shared.so",       "#{target_lib_dir}/lib/"
      FileUtils.cp "#{release_dir}/libs/armeabi-v7a/libsupc++.a",               "#{target_lib_dir}/lib/"
      FileUtils.cp "#{release_dir}/libs/armeabi-v7a/libgnustl_static.a",        "#{target_lib_dir}/lib/libstdc++.a"
      FileUtils.cp "#{release_dir}/libs/armeabi-v7a/thumb/libgnustl_shared.so", "#{target_lib_dir}/lib/thumb/"
      FileUtils.cp "#{release_dir}/libs/armeabi-v7a/thumb/libsupc++.a",         "#{target_lib_dir}/lib/thumb/"
      FileUtils.cp "#{release_dir}/libs/armeabi-v7a/thumb/libgnustl_static.a",  "#{target_lib_dir}/lib/thumb/libstdc++.a"
      #
      FileUtils.cp "#{release_dir}/libs/armeabi-v7a/libgnustl_shared.so",       "#{target_lib_dir}/lib/armv7-a/"
      FileUtils.cp "#{release_dir}/libs/armeabi-v7a/libsupc++.a",               "#{target_lib_dir}/lib/armv7-a/"
      FileUtils.cp "#{release_dir}/libs/armeabi-v7a/libgnustl_static.a",        "#{target_lib_dir}/lib/armv7-a/libstdc++.a"
      FileUtils.cp "#{release_dir}/libs/armeabi-v7a/thumb/libgnustl_shared.so", "#{target_lib_dir}/lib/armv7-a/thumb/"
      FileUtils.cp "#{release_dir}/libs/armeabi-v7a/thumb/libsupc++.a",         "#{target_lib_dir}/lib/armv7-a/thumb/"
      FileUtils.cp "#{release_dir}/libs/armeabi-v7a/thumb/libgnustl_static.a",  "#{target_lib_dir}/lib/armv7-a/thumb/libstdc++.a"
      #
      FileUtils.cp "#{release_dir}/libs/armeabi-v7a-hard/libgnustl_shared.so",       "#{target_lib_dir}/lib/armv7-a/hard/"
      FileUtils.cp "#{release_dir}/libs/armeabi-v7a-hard/libsupc++.a",               "#{target_lib_dir}/lib/armv7-a/hard/"
      FileUtils.cp "#{release_dir}/libs/armeabi-v7a-hard/libgnustl_static.a",        "#{target_lib_dir}/lib/armv7-a/hard/libstdc++.a"
      FileUtils.cp "#{release_dir}/libs/armeabi-v7a-hard/thumb/libgnustl_shared.so", "#{target_lib_dir}/lib/armv7-a/thumb/hard/"
      FileUtils.cp "#{release_dir}/libs/armeabi-v7a-hard/thumb/libsupc++.a",         "#{target_lib_dir}/lib/armv7-a/thumb/hard/"
      FileUtils.cp "#{release_dir}/libs/armeabi-v7a-hard/thumb/libgnustl_static.a",  "#{target_lib_dir}/lib/armv7-a/thumb/hard/libstdc++.a"
      #
      FileUtils.mkdir_p ["#{arch_include_dir}/armv7-a/thumb", "#{arch_include_dir}/armv7-a/thumb", "#{arch_include_dir}/armv7-a/hard", "#{arch_include_dir}/armv7-a/thumb/hard"]
      # todo: ?
      FileUtils.cp_r "#{release_dir}/libs/armeabi-v7a/include/bits",      "#{arch_include_dir}/"
      FileUtils.cp_r "#{release_dir}/libs/armeabi-v7a/include/bits",      "#{arch_include_dir}/thumb/"
      #
      FileUtils.cp_r "#{release_dir}/libs/armeabi-v7a/include/bits",      "#{arch_include_dir}/armv7-a/"
      FileUtils.cp_r "#{release_dir}/libs/armeabi-v7a/include/bits",      "#{arch_include_dir}/armv7-a/thumb/"
      FileUtils.cp_r "#{release_dir}/libs/armeabi-v7a-hard/include/bits", "#{arch_include_dir}/armv7-a/hard"
      FileUtils.cp_r "#{release_dir}/libs/armeabi-v7a-hard/include/bits", "#{arch_include_dir}/armv7-a/thumb/hard"
    when 'mips'
      FileUtils.cp "#{release_dir}/libs/mips/lib/libgnustl_shared.so", "#{target_lib_dir}/lib/"
      FileUtils.cp "#{release_dir}/libs/mips/lib/libsupc++.a",         "#{target_lib_dir}/lib/"
      FileUtils.cp "#{release_dir}/libs/mips/lib/libgnustl_static.a",  "#{target_lib_dir}/lib/libstdc++.a"
      #
      FileUtils.cp "#{release_dir}/libs/mips/libr2/libgnustl_shared.so", "#{target_lib_dir}/libr2/"
      FileUtils.cp "#{release_dir}/libs/mips/libr2/libsupc++.a",         "#{target_lib_dir}/libr2/"
      FileUtils.cp "#{release_dir}/libs/mips/libr2/libgnustl_static.a",  "#{target_lib_dir}/libr2/libstdc++.a"
      #
      FileUtils.cp "#{release_dir}/libs/mips/libr6/libgnustl_shared.so", "#{target_lib_dir}/libr6/"
      FileUtils.cp "#{release_dir}/libs/mips/libr6/libsupc++.a",         "#{target_lib_dir}/libr6/"
      FileUtils.cp "#{release_dir}/libs/mips/libr6/libgnustl_static.a",  "#{target_lib_dir}/libr6/libstdc++.a"
      #
      FileUtils.mkdir_p ["#{arch_include_dir}/mips-r2", "#{arch_include_dir}/mips-r6"]
      FileUtils.cp_r "#{release_dir}/libs/mips/include/bits", "#{arch_include_dir}/"
      FileUtils.cp_r "#{release_dir}/libs/mips/include/bits", "#{arch_include_dir}/mips-r2"
      FileUtils.cp_r "#{release_dir}/libs/mips/include/bits", "#{arch_include_dir}/mips-r6"
    when 'x86_64'
      FileUtils.cp "#{release_dir}/libs/x86_64/lib/libgnustl_shared.so", "#{target_lib_dir}/lib/"
      FileUtils.cp "#{release_dir}/libs/x86_64/lib/libsupc++.a",         "#{target_lib_dir}/lib/"
      FileUtils.cp "#{release_dir}/libs/x86_64/lib/libgnustl_static.a",  "#{target_lib_dir}/lib/libstdc++.a"
      #
      FileUtils.cp "#{release_dir}/libs/x86_64/lib64/libgnustl_shared.so", "#{target_lib_dir}/lib64/"
      FileUtils.cp "#{release_dir}/libs/x86_64/lib64/libsupc++.a",         "#{target_lib_dir}/lib64/"
      FileUtils.cp "#{release_dir}/libs/x86_64/lib64/libgnustl_static.a",  "#{target_lib_dir}/lib64/libstdc++.a"
      #
      FileUtils.cp "#{release_dir}/libs/x86_64/libx32/libgnustl_shared.so", "#{target_lib_dir}/libx32/"
      FileUtils.cp "#{release_dir}/libs/x86_64/libx32/libsupc++.a",         "#{target_lib_dir}/libx32/"
      FileUtils.cp "#{release_dir}/libs/x86_64/libx32/libgnustl_static.a",  "#{target_lib_dir}/libx32/libstdc++.a"
      #
      FileUtils.mkdir_p ["#{arch_include_dir}/32", "#{arch_include_dir}/x32"]
      FileUtils.cp_r "#{release_dir}/libs/x86_64/include/32/bits",  "#{arch_include_dir}/32/"
      FileUtils.cp_r "#{release_dir}/libs/x86_64/include/bits",     "#{arch_include_dir}/"
      FileUtils.cp_r "#{release_dir}/libs/x86_64/include/x32/bits", "#{arch_include_dir}/x32/"
    when 'mips64'
      FileUtils.cp "#{release_dir}/libs/mips64/lib/libgnustl_shared.so", "#{target_lib_dir}/lib/"
      FileUtils.cp "#{release_dir}/libs/mips64/lib/libsupc++.a",         "#{target_lib_dir}/lib/"
      FileUtils.cp "#{release_dir}/libs/mips64/lib/libgnustl_static.a",  "#{target_lib_dir}/lib/libstdc++.a"
      #
      FileUtils.cp "#{release_dir}/libs/mips64/libr2/libgnustl_shared.so", "#{target_lib_dir}/libr2/"
      FileUtils.cp "#{release_dir}/libs/mips64/libr2/libsupc++.a",         "#{target_lib_dir}/libr2/"
      FileUtils.cp "#{release_dir}/libs/mips64/libr2/libgnustl_static.a",  "#{target_lib_dir}/libr2/libstdc++.a"
      #
      FileUtils.cp "#{release_dir}/libs/mips64/libr6/libgnustl_shared.so", "#{target_lib_dir}/libr6/"
      FileUtils.cp "#{release_dir}/libs/mips64/libr6/libsupc++.a",         "#{target_lib_dir}/libr6/"
      FileUtils.cp "#{release_dir}/libs/mips64/libr6/libgnustl_static.a",  "#{target_lib_dir}/libr6/libstdc++.a"
      #
      FileUtils.cp "#{release_dir}/libs/mips64/lib64/libgnustl_shared.so", "#{target_lib_dir}/lib64/"
      FileUtils.cp "#{release_dir}/libs/mips64/lib64/libsupc++.a",         "#{target_lib_dir}/lib64/"
      FileUtils.cp "#{release_dir}/libs/mips64/lib64/libgnustl_static.a",  "#{target_lib_dir}/lib64/libstdc++.a"
      #
      FileUtils.cp "#{release_dir}/libs/mips64/lib64r2/libgnustl_shared.so", "#{target_lib_dir}/lib64r2/"
      FileUtils.cp "#{release_dir}/libs/mips64/lib64r2/libsupc++.a",         "#{target_lib_dir}/lib64r2/"
      FileUtils.cp "#{release_dir}/libs/mips64/lib64r2/libgnustl_static.a",  "#{target_lib_dir}/lib64r2/libstdc++.a"
      #
      FileUtils.mkdir_p ["#{arch_include_dir}/32/mips-r1/", "#{arch_include_dir}/32/mips-r2/", "#{arch_include_dir}/32/mips-r6/", "#{arch_include_dir}/mips64-r2/"]
      FileUtils.cp_r "#{release_dir}/libs/mips64/include/32/mips-r1/bits",  "#{arch_include_dir}/32/mips-r1/"
      FileUtils.cp_r "#{release_dir}/libs/mips64/include/32/mips-r2/bits",  "#{arch_include_dir}/32/mips-r2/"
      FileUtils.cp_r "#{release_dir}/libs/mips64/include/32/mips-r6/bits",  "#{arch_include_dir}/32/mips-r6/"
      FileUtils.cp_r "#{release_dir}/libs/mips64/include/bits",             "#{arch_include_dir}/"
      FileUtils.cp_r "#{release_dir}/libs/mips64/include/mips64-r2/bits",   "#{arch_include_dir}/mips64-r2/"
    else
      FileUtils.cp "#{release_dir}/libs/#{arch.abis[0]}/libgnustl_shared.so", "#{target_lib_dir}/lib/"
      FileUtils.cp "#{release_dir}/libs/#{arch.abis[0]}/libsupc++.a",         "#{target_lib_dir}/lib/"
      FileUtils.cp "#{release_dir}/libs/#{arch.abis[0]}/libgnustl_static.a",  "#{target_lib_dir}/lib/libstdc++.a"
      #
      FileUtils.cp_r "#{release_dir}/libs/#{arch.abis[0]}/include/bits", "#{arch_include_dir}/"
    end
  end

  def copy_sysroot(arch, sysroot_dir)
    FileUtils.mkdir_p sysroot_dir
    FileUtils.cp_r "#{Global::NDK_DIR}/platforms/android-#{arch.min_api_level}/arch-#{arch}/usr", sysroot_dir
    usr_dir = "#{sysroot_dir}/usr"
    # copy crystax library
    arch.abis.each do |abi|
      crystax_libdir = "#{Global::NDK_DIR}/sources/crystax/libs/#{abi}"
      case abi
      when 'x86_64'
        FileUtils.cp Dir["#{crystax_libdir}/libcrystax.*"],     "#{usr_dir}/lib64/"
        FileUtils.cp Dir["#{crystax_libdir}/32/libcrystax.*"],  "#{usr_dir}/lib/"
        FileUtils.cp Dir["#{crystax_libdir}/x32/libcrystax.*"], "#{usr_dir}/libx32/"
      when 'mips64'
        FileUtils.cp Dir["#{crystax_libdir}/libcrystax.*"],         "#{usr_dir}/lib64"
        FileUtils.cp Dir["#{crystax_libdir}/libr2/libcrystax.*"],   "#{usr_dir}/lib64r2"
        FileUtils.cp Dir["#{crystax_libdir}/lib32/libcrystax.*"],   "#{usr_dir}/lib"
        FileUtils.cp Dir["#{crystax_libdir}/lib32r2/libcrystax.*"], "#{usr_dir}/libr2"
        FileUtils.cp Dir["#{crystax_libdir}/lib32r6/libcrystax.*"], "#{usr_dir}/libr6"
      when 'mips'
        FileUtils.cp Dir["#{crystax_libdir}/libcrystax.*"],    "#{usr_dir}/lib"
        FileUtils.cp Dir["#{crystax_libdir}/r2/libcrystax.*"], "#{usr_dir}/libr2"
        FileUtils.cp Dir["#{crystax_libdir}/r6/libcrystax.*"], "#{usr_dir}/libr6"
      when 'armeabi-v7a'
        FileUtils.mkdir_p "#{usr_dir}/lib/armv7-a/thumb"
        FileUtils.cp Dir["#{crystax_libdir}/libcrystax.*"],       "#{usr_dir}/lib/armv7-a/"
        FileUtils.cp Dir["#{crystax_libdir}/thumb/libcrystax.*"], "#{usr_dir}/lib/armv7-a/thumb/"
      when 'armeabi-v7a-hard'
        FileUtils.mkdir_p "#{usr_dir}/lib/armv7-a/hard"
        FileUtils.mkdir_p "#{usr_dir}/lib/armv7-a/thumb/hard"
        FileUtils.cp Dir["#{crystax_libdir}/libcrystax.*"],       "#{usr_dir}/lib/armv7-a/hard/"
        FileUtils.cp Dir["#{crystax_libdir}/thumb/libcrystax.*"], "#{usr_dir}/lib/armv7-a/thumb/hard/"
      when 'x86', 'arm64-v8a'
        FileUtils.cp Dir["#{crystax_libdir}/libcrystax.*"], "#{usr_dir}/lib/"
      else
        raise "copying sysroot for unsupported abi #{abi}"
      end
    end
  end

  def build_for_abi(abi, toolchain, release, sysroot, install_dir, options)
    arch = Build.arch_for_abi(abi)
    setup_build_env abi, toolchain, sysroot, options
    install_dir += "/thumb" if options[:thumb]

    args =  ["--prefix=#{install_dir}",
             "--host=#{arch.host}",
             "--enable-libstdcxx-time",
             "--disable-symvers",
             "--disable-nls",
             "--disable-tls",
             "--disable-libstdcxx-pch",
             "--with-gxx-include-dir=#{install_dir}/include/c++/#{release.version}"
            ]

    args += ['--disable-static', '--enable-shared']                                   if options[:lib_type] == :shared
    args += ['--enable-static', '--disable-shared', '--disable-libstdcxx-visibility'] if options[:lib_type] == :static
    args << '--disable-multilib'                                                      unless ['x86_64', 'mips64', 'mips'].include? arch.name
    args << '--disable-sjlj-exceptions'                                               if ['4.9', '5'].include? release.version

    build_dir = options[:lib_type].to_s
    build_dir += '_thumb' if options[:thumb]
    src_dir = "#{Build::TOOLCHAIN_SRC_DIR}/gcc/gcc-#{release.version}/libstdc++-v3"
    FileUtils.mkdir build_dir
    FileUtils.cd(build_dir) do
      system "#{src_dir}/configure", *args
      system 'make', '-j', num_jobs
      system 'make', 'install'
    end
  end

  def setup_build_env(abi, toolchain, sysroot, options)
    arch = Build.arch_for_abi(abi)

    extra_cflags  = '-ffunction-sections -fdata-sections'
    extra_ldflags = ''
    if options[:thumb]
        extra_cflags += ' -mthumb'
        extra_ldflags = '-mthumb'
    end
    extra_cflags += ' -mstackrealign' if ['x86', 'x86_64'].include? arch

    cflags   = "-g -fPIC --sysroot=#{sysroot} -fexceptions -funwind-tables -D__BIONIC__ -O2 #{extra_cflags}"
    cppflags = "--sysroot=#{sysroot}"
    ldflags  = "-lcrystax #{extra_ldflags} -lc"

    case arch.name
    when 'arm64'
      cflags += ' -mfix-cortex-a53-835769'
    when 'arm'
      cflags += ' -march=armv7-a -mfpu=vfpv3-d16 -minline-thumb1-jumptable'
      ldflags += ' -Wl,--fix-cortex-a8'
      if not abi == 'armeabi-v7a-hard'
        cflags += ' -mfloat-abi=softfp'
      else
        cflags += ' -mhard-float -D_NDK_MATH_NO_SOFTFP=1'
        ldflags += ' -Wl,--no-warn-mismatch -lm_hard'
      end
    end

    cxxflags = "#{cflags} -frtti"
    cxxflags += ' -fvisibility=hidden -fvisibility-inlines-hidden' if options[:lib_type] == :static

    cc = toolchain.c_compiler(arch, abi)
    cxx = toolchain.cxx_compiler(arch, abi)

    @build_env = {'CC'       => cc,
                  'CXX'      => cxx,
                  'CPP'      => "#{cc} -E",
                  'AR'       => toolchain.tool(arch, 'ar'),
                  'AS'       => toolchain.tool(arch, 'as'),
                  'RANLIB'   => toolchain.tool(arch, 'ranlib'),
                  'READELF'  => toolchain.tool(arch, 'readelf'),
                  'LD'       => toolchain.tool(arch, 'ld'),
                  'STRIP'    => toolchain.tool(arch, 'strip'),
                  'CPPFLAGS' => cppflags,
                  'CFLAGS'   => cflags,
                  'CXXFLAGS' => cxxflags,
                  'LDFLAGS'  => ldflags
                 }
  end

  def copy_installed_files(abi, release, install_dir)
    arch = Build.arch_for_abi(abi)
    dst_dir = "#{package_dir}/#{archive_sub_dir(release)}"

    copy_directory "#{install_dir}/include/c++/#{release.version}", "#{dst_dir}/include"
    FileUtils.rm_rf "#{dst_dir}/include/#{arch.host}"

    # Copy the ABI-specific headers
    copy_directory "#{install_dir}/include/c++/#{release.version}/#{arch.host}/bits", "#{dst_dir}/libs/#{abi}/include/bits"
    case arch.name
    when 'x86_64'
      copy_directory "#{install_dir}/include/c++/#{release.version}/#{arch.host}/32/bits",  "#{dst_dir}/libs/#{abi}/include/32/bits"
      copy_directory "#{install_dir}/include/c++/#{release.version}/#{arch.host}/x32/bits", "#{dst_dir}/libs/#{abi}/include/x32/bits"
    when 'mips64'
      copy_directory "#{install_dir}/include/c++/#{release.version}/#{arch.host}/32/mips-r1/bits", "#{dst_dir}/libs/#{abi}/include/32/mips-r1/bits"
      copy_directory "#{install_dir}/include/c++/#{release.version}/#{arch.host}/32/mips-r2/bits", "#{dst_dir}/libs/#{abi}/include/32/mips-r2/bits"
      copy_directory "#{install_dir}/include/c++/#{release.version}/#{arch.host}/32/mips-r6/bits", "#{dst_dir}/libs/#{abi}/include/32/mips-r6/bits"
      copy_directory "#{install_dir}/include/c++/#{release.version}/#{arch.host}/mips64-r2/bits",  "#{dst_dir}/libs/#{abi}/include/mips64-r2/bits"
    when 'mips'
      copy_directory "#{install_dir}/include/c++/#{release.version}/#{arch.host}/mips-r2/bits", "#{dst_dir}/libs/#{abi}/include/mips-r2/bits"
      copy_directory "#{install_dir}/include/c++/#{release.version}/#{arch.host}/mips-r6/bits", "#{dst_dir}/libs/#{abi}/include/mips-r6/bits"
    end

    ldir = (arch.num_bits == 64) ? 'lib64' : 'lib'

    # Copy the ABI-specific libraries
    # Note: the shared library name is libgnustl_shared.so due our custom toolchain patch
    lib_list = ['libsupc++.a', 'libgnustl_shared.so']
    copy_file_list "#{install_dir}/#{ldir}", "#{dst_dir}/libs/#{abi}",  lib_list
    # Note: we need to rename libgnustl_shared.a to libgnustl_static.a
    FileUtils.cp "#{install_dir}/#{ldir}/libgnustl_shared.a", "#{dst_dir}/libs/#{abi}/libgnustl_static.a"
    # for multilib we copy full set. Keep native libs in $ABI dir for compatibility.
    # TODO: remove it in $ABI top directory
    case arch.name
    when 'x86_64'
      copy_file_list "#{install_dir}/lib",    "#{dst_dir}/libs/#{abi}/lib",    lib_list
      copy_file_list "#{install_dir}/lib64",  "#{dst_dir}/libs/#{abi}/lib64",  lib_list
      copy_file_list "#{install_dir}/libx32", "#{dst_dir}/libs/#{abi}/libx32", lib_list
      #
      FileUtils.cp "#{install_dir}/lib/libgnustl_shared.a",    "#{dst_dir}/libs/#{abi}/lib/libgnustl_static.a"
      FileUtils.cp "#{install_dir}/lib64/libgnustl_shared.a",  "#{dst_dir}/libs/#{abi}/lib64/libgnustl_static.a"
      FileUtils.cp "#{install_dir}/libx32/libgnustl_shared.a", "#{dst_dir}/libs/#{abi}/libx32/libgnustl_static.a"
    when 'mips64'
      copy_file_list "#{install_dir}/lib",     "#{dst_dir}/libs/#{abi}/lib",     lib_list
      copy_file_list "#{install_dir}/libr2",   "#{dst_dir}/libs/#{abi}/libr2",   lib_list
      copy_file_list "#{install_dir}/libr6",   "#{dst_dir}/libs/#{abi}/libr6",   lib_list
      copy_file_list "#{install_dir}/lib64",   "#{dst_dir}/libs/#{abi}/lib64",   lib_list
      copy_file_list "#{install_dir}/lib64r2", "#{dst_dir}/libs/#{abi}/lib64r2", lib_list
      #
      FileUtils.cp "#{install_dir}/lib/libgnustl_shared.a",     "#{dst_dir}/libs/#{abi}/lib/libgnustl_static.a"
      FileUtils.cp "#{install_dir}/libr2/libgnustl_shared.a",   "#{dst_dir}/libs/#{abi}/libr2/libgnustl_static.a"
      FileUtils.cp "#{install_dir}/libr6/libgnustl_shared.a",   "#{dst_dir}/libs/#{abi}/libr6/libgnustl_static.a"
      FileUtils.cp "#{install_dir}/lib64/libgnustl_shared.a",   "#{dst_dir}/libs/#{abi}/lib64/libgnustl_static.a"
      FileUtils.cp "#{install_dir}/lib64r2/libgnustl_shared.a", "#{dst_dir}/libs/#{abi}/lib64r2/libgnustl_static.a"
    when 'mips'
      copy_file_list "#{install_dir}/lib",   "#{dst_dir}/libs/#{abi}/lib",   lib_list
      copy_file_list "#{install_dir}/libr2", "#{dst_dir}/libs/#{abi}/libr2", lib_list
      copy_file_list "#{install_dir}/libr6", "#{dst_dir}/libs/#{abi}/libr6", lib_list
      #
      FileUtils.cp "#{install_dir}/lib/libgnustl_shared.a",   "#{dst_dir}/libs/#{abi}/lib/libgnustl_static.a"
      FileUtils.cp "#{install_dir}/libr2/libgnustl_shared.a", "#{dst_dir}/libs/#{abi}/libr2/libgnustl_static.a"
      FileUtils.cp "#{install_dir}/libr6/libgnustl_shared.a", "#{dst_dir}/libs/#{abi}/libr6/libgnustl_static.a"
    end

    if File.directory? "#{install_dir}/thumb"
      copy_file_list "#{install_dir}/thumb/lib", "#{dst_dir}/libs/#{abi}/thumb", lib_list
      FileUtils.cp "#{install_dir}/thumb/lib/libgnustl_shared.a", "#{dst_dir}/libs/#{abi}/thumb/libgnustl_static.a"
    end
  end

  def select_gcc(ver)
    case ver
    when '4.9' then Toolchain::GCC_4_9
    when '5'   then Toolchain::GCC_5
    when '6'   then Toolchain::GCC_6
    else
      raise "no GCC version for libstdc++ version: #{version}"
    end
  end

  def package_dir
    "#{build_base_dir}/package"
  end

  def archive_sub_dir(release)
    "sources/cxx-stl/gnu-libstdc++/#{release.version}"
  end

  def copy_directory(s, d)
    FileUtils.mkdir_p d
    FileUtils.cd(s) { FileUtils.cp_r Dir['*'], d }
  end

  def copy_file_list(s, d, list)
    FileUtils.mkdir_p d
    FileUtils.cd(s) { FileUtils.cp list, d }
  end
end
