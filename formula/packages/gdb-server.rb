class GdbServer < BasePackage

  desc "GDB server"
  # todo:
  #homepage ""
  #url "https://www.cs.princeton.edu/~bwk/btl.mirror/awk.tar.gz"

  release version: '7.10', crystax_version: 1, sha256: '3dc5577659c609c3643c55c5f393c174caa04c9f848d285f7618c4257aad960a'

  # todo:
  #build_depends_on default_compiler
  depends_on 'platforms'

  ARCHIVE_SUB_DIRS  = Build::ARCH_LIST.map { |arch| "android-#{arch}" }
  API_LEVEL = 21

  def release_directory(_release = nil, _platform_name = nil)
    File.join Global::NDK_DIR, 'prebuilt'
  end

  def install_archive(release, archive, _platform_name = nil)
    prop_dir = properties_directory(release)
    FileUtils.mkdir_p prop_dir
    prop = get_properties(prop_dir)

    FileUtils.rm_rf ARCHIVE_SUB_DIRS.map { |d| File.join release_directory, d }
    Utils.unpack archive, Global::NDK_DIR

    prop[:installed] = true
    prop[:installed_crystax_version] = release.crystax_version
    save_properties prop, prop_dir

    release.installed = release.crystax_version
  end

  def build(release, options, _host_dep_dirs, _target_dep_dirs)
    arch_list = Build.abis_to_arch_list(options.abis)
    puts "Building #{name} #{release} for architectures: #{arch_list.map{|a| a.name}.join(' ')}"

    FileUtils.rm_rf build_base_dir

    FileUtils.rm_rf build_base_dir
    @log_file = build_log_file
    @num_jobs = options.num_jobs
    src_dir = "#{Build::TOOLCHAIN_SRC_DIR}/gdb/gdb-#{release.version}/gdb/gdbserver"
    package_dir = "#{build_base_dir}/package"

    toolchain = Build::DEFAULT_TOOLCHAIN

    arch_list.each do |arch|
      puts "= building for architecture: #{arch}"
      base_arch_dir = "#{build_base_dir}/#{arch}"
      build_dir = "#{base_arch_dir}/build"
      sysroot_dir = "#{base_arch_dir}/sysroot"
      prepare_sysroot arch, sysroot_dir, toolchain
      FileUtils.mkdir_p build_dir
      FileUtils.cd(build_dir) { build_for_arch arch, toolchain, src_dir, sysroot_dir, package_dir }
      FileUtils.rm_rf base_arch_dir unless options.no_clean?
    end

    if options.build_only?
      puts "Build only, no packaging and installing"
    else
      # pack archive and copy into cache dir
      archive = cache_file(release)
      puts "Creating archive file #{archive}"
      Utils.pack archive, package_dir

      if options.update_shasum?
        release.shasum = Digest::SHA256.hexdigest(File.read(archive, mode: "rb"))
        update_shasum release
      end

      if options.install?
        puts "Unpacking archive into #{release_directory}"
        install_archive release, archive
      end
    end

    if options.no_clean?
      puts "No cleanup, for build artifacts see #{build_base_dir}"
    else
      FileUtils.rm_rf build_base_dir
    end
  end

  def prepare_sysroot(arch, sysroot_dir, toolchain)
    FileUtils.mkdir_p sysroot_dir
    FileUtils.cp_r Dir["#{Global::NDK_DIR}/platforms/android-#{API_LEVEL}/arch-#{arch}/*"], sysroot_dir

    # Don't use CrystaX headers when building gdbserver
    FileUtils.cp_r Dir["#{sysroot_dir}/usr/include/crystax/google/*"], "#{sysroot_dir}/usr/include"
    FileUtils.rm_rf Dir["#{sysroot_dir}/usr/include/crystax*"]

    # restore original (non patched) libraries
    Dir["#{sysroot_dir}/usr/*"].each do |dir|
      next if dir.end_with? 'include'
      FileUtils.cd(dir) do
        FileUtils.rm_f Dir['*'].delete_if { |f| File.directory? f }
        FileUtils.cp Dir['google/*'], '.'
        FileUtils.rm_rf 'google'
      end
    end

    # copy empty libcrystax
    FileUtils.mkdir_p "#{sysroot_dir}/usr/lib" # todo: why?
    ['lib', 'lib64', 'lib64r2', 'libr2', 'libr6'].each do |lib|
      dir = "#{sysroot_dir}/usr/#{lib}"
      FileUtils.cp "#{Global::NDK_DIR}/sources/crystax/empty/libcrystax.a", dir if Dir.exist? dir
    end
    # Remove libthread_db to ensure we use exactly the one we want.
    FileUtils.rm_f Dir["#{sysroot_dir}/usr/#{arch.default_lib_dir}/libthread_db*"]
    FileUtils.rm_f "#{sysroot_dir}/usr/include/thread_db.h"

    # We're going to rebuild libthread_db.o from its source
    # that is under sources/android/libthread_db and place its header
    # and object file into the build sysroot.
    libthread_db_dir = "#{Global::NDK_DIR}/sources/android/libthread_db"
    raise "Missing directory: #{libthread_db_dir}" unless Dir.exist? libthread_db_dir
    FileUtils.cp "#{libthread_db_dir}/thread_db.h", "#{sysroot_dir}/usr/include/"
    cc = toolchain.c_compiler(arch, '')
    ar = toolchain.tool(arch, 'ar')
    system cc, "--sysroot=#{sysroot_dir}", '-o', "#{sysroot_dir}/usr/#{arch.default_lib_dir}/libthread_db.o", '-c', "#{libthread_db_dir}/libthread_db.c"
    system ar, '-rD', "#{sysroot_dir}/usr/#{arch.default_lib_dir}/libthread_db.a", "#{sysroot_dir}/usr/#{arch.default_lib_dir}/libthread_db.o"
  end

  def build_for_arch(arch, toolchain, src_dir, sysroot_dir, package_dir)
    host, cflags = arch_specifics(arch)

    args = ["--host=#{host}",
            "--with-libthread-db=#{sysroot_dir}/usr/#{arch.default_lib_dir}/libthread_db.a",
            "--disable-inprocess-agent",
            "--enable-werror=no"
           ]

    build_env['CC']      = "#{toolchain.c_compiler(arch, '')} --sysroot=#{sysroot_dir}"
    build_env['AR']      = toolchain.tool(arch, 'ar')
    build_env['RANLIB']  = toolchain.tool(arch, 'ranlib')
    build_env['CFLAGS']  = cflags
    build_env['LDFLAGS'] = '-lcrystax -lm -lc -static -Wl,-z,muldefs -Wl,-z,nocopyreloc -Wl,--no-undefined'

    system "#{src_dir}/configure", *args
    system 'make', '-j', num_jobs

    install_dir = "#{package_dir}/prebuilt/android-#{arch}/gdbserver"
    FileUtils.mkdir_p install_dir
    system toolchain.tool(arch, 'objcopy'), '--strip-unneeded', './gdbserver', "#{install_dir}/gdbserver"
  end

  def arch_specifics(arch)
    case arch.name
    when 'arm'
      ['arm-eabi-linux', '-fno-short-enums']
    when 'x86'
      ['i686-linux-android', '']
    when 'mips'
      ['mipsel-linux-android', '']
    when 'arm64'
      ['aarch64-eabi-linux', '-fno-short-enums -DUAPI_HEADERS']
    when 'x86_64'
      ['x86_64-linux-android', '-DUAPI_HEADERS']
    when 'mips64'
      ['mips64el-linux-android', '-DUAPI_HEADERS']
    else
      raise UnsupportedArch, arch
    end
  end
end
