class Gcc < Tool

  include MultiVersion

  desc "GCC-based toolchain"
  homepage "https://gcc.gnu.org"
  url "toolchain/gcc"

  release '4.9', crystax: 6
  release '5',   crystax: 7
  release '6',   crystax: 7
  release '7',   crystax: 3
  release '8',   crystax: 1
  release '9',   crystax: 1

  build_depends_on 'gmp'
  build_depends_on 'isl'
  build_depends_on 'ppl'
  build_depends_on 'mpc'
  build_depends_on 'mpfr'
  build_depends_on 'cloog'
  build_depends_on 'expat'
  build_depends_on 'isl-old'
  build_depends_on 'cloog-old'
  build_depends_on 'python'

  ARCHIVE_TOP_DIR  = 'toolchains'
  UNWIND_SUB_DIR   = 'sources/android/gccunwind/libs'
  LICENSES_SUB_DIR = 'build/instruments/toolchain-licenses'

  LICENSE_MASK = 'COPYING*'

  GDB_VER = '7.10'

  Lib = Struct.new(:name, :version, :url, :args, :templates)

  def remove_installed_files(release, platform_name, clean_lib_unwind)
    unwind_dir = File.join(Global::NDK_DIR, UNWIND_SUB_DIR)
    FileUtils.rm_rf unwind_dir if clean_lib_unwind

    Arch::LIST.values.each do |arch|
      toolchain_dir = File.join(Global::NDK_DIR, ARCHIVE_TOP_DIR, "#{arch.toolchain}-#{release.version}")
      FileUtils.rm_rf File.join(toolchain_dir, 'prebuilt', platform_name)
      FileUtils.rm_rf toolchain_dir if Dir["#{toolchain_dir}/prebuilt/*"].empty?
    end
  end

  def install_archive(release, archive, platform_name)
    rel_dir = release_directory(release, platform_name)
    FileUtils.mkdir_p rel_dir unless Dir.exists? rel_dir
    prop = get_properties(rel_dir)

    remove_installed_files release, platform_name, prop[:libunwind_installed]
    Utils.unpack archive, Global::NDK_DIR

    prop.merge! get_properties(rel_dir)
    prop[:installed] = true
    prop[:installed_crystax_version] = release.crystax_version
    prop[:libunwind_installed] = Toolchain::DEFAULT_GCC.version == release.version
    save_properties prop, rel_dir

    release.installed = release.crystax_version
  end

  def uninstall(release, platform_name = Global::PLATFORM_NAME)
    puts "removing #{name}:#{release.version} #{platform_name}"

    rel_dir = release_directory(release, platform_name)
    prop = get_properties(rel_dir)

    remove_installed_files release, platform_name, prop[:libunwind_installed]

    prop[:installed] = false
    prop.delete :installed_crystax_version
    prop.delete :libunwind_installed
    prop.delete :build_info
    save_properties prop, rel_dir

    release.installed = false
  end

  # this method does not make much sense without ARCH name
  # defined only for the sake of completeness
  def code_directory(release, platform_name)
    File.join(Global::NDK_DIR, ARCHIVE_TOP_DIR)
  end

  def build(release, options, host_dep_info, _target_dep_info)
    platforms = options.platforms.map { |name| Platform.new(name) }
    arch_list = Build.abis_to_arch_list(options.abis)
    puts "Building #{name} #{release} for platforms: #{platforms.map(&:name).join(', ')}; for architectures: #{arch_list.map(&:name).join(', ')}"

    self.num_jobs = options.num_jobs

    parse_host_dep_info host_dep_info

    FileUtils.rm_rf build_base_dir

    platforms.each do |platform|
      puts "= building for #{platform.name}"

      arch_list.each do |arch|
        base_dir = base_dir(platform, arch)
        self.log_file = build_log_file(base_dir)
        printf  "  %-#{max_arch_name_len(arch_list)+1}s ", "#{arch.name}:"
        # todo:
        if canadian_build? platform
          # when building widows based toolchain (or darwin based on linux) we must at first build toolchain
          # that targets the same arch and works on the host we're building on
          host_platform = Platform.new(Global::PLATFORM_NAME)
          update_host_dep_dirs platform, host_platform
          build_toolchain host_platform, arch, release, File.join(base_dir, 'host'), build_gdb: false, strip_executables: false
          print '   '
        end
        build_toolchain platform, arch, release, base_dir
        puts ""
      end

      if not options.build_only?
        pkg_dir = File.join(build_base_dir, platform.name, ARCHIVE_TOP_DIR)
        arch_list.each do |arch|
          base_dir = base_dir(platform, arch)
          arch_pkg_dir = File.join(pkg_dir, "#{arch.toolchain}-#{release.version}", 'prebuilt', platform.name)
          FileUtils.mkdir_p arch_pkg_dir
          FileUtils.cd(install_dir(base_dir)) do
            # remove unneeded files
            FileUtils.rm_f  Dir['bin/*-run*']
            FileUtils.rm_rf ['share/info', 'share/man']
            FileUtils.rm_rf Dir["lib/gcc/#{arch.host}/*/install-tools"] + Dir['libexec/**/install-tools'] + Dir["lib/gcc/#{arch.host}/*/plugin"]
            FileUtils.rm_f  Dir['**/*.la']
            # copy to package dir
            FileUtils.cp  Dir[File.join(Global::NDK_DIR, LICENSES_SUB_DIR, 'COPYING*')], arch_pkg_dir
            FileUtils.cp_r [arch.host, 'bin', 'include', 'lib', 'libexec', 'share'], arch_pkg_dir
          end
          create_libgccunwind platform, arch, base_dir if Toolchain::DEFAULT_GCC.version == release.version
        end

        write_build_info platform.name, release

        archive = cache_file(release, platform.name)
        puts "= packaging #{archive}"
        dirs = [ARCHIVE_TOP_DIR, File.basename(Global::SERVICE_DIR)]
        dirs << UNWIND_SUB_DIR.split('/')[0] if Toolchain::DEFAULT_GCC.version == release.version
        Utils.pack archive, base_dir_for_platform(platform.name), *dirs

        update_shasum release, platform.name if options.update_shasum?

        if options.install?
          puts "= installing #{archive}"
          install_archive release, archive, platform.name
        end
      end

      FileUtils.rm_rf base_dir_for_platform(platform.name) unless options.no_clean?
    end

    if options.no_clean?
      puts "No cleanup, for build artifacts see #{build_base_dir}"
    else
      FileUtils.rm_rf build_base_dir
    end
  end

  private

  def canadian_build?(platform)
    platform.cross_compile?
  end

  def build_toolchain(platform, arch, release, base_dir, params = { build_gdb: true, strip_executables: true })
    # prepare base dirs and log file
    install_dir = install_dir(base_dir)
    FileUtils.mkdir_p install_dir

    # copy sysroot
    sysroot_dir = File.join(install_dir, 'sysroot')
    copy_sysroot arch, sysroot_dir

    common_args = ["--prefix=#{install_dir}",
                   "--target=#{arch.host}",
                   "--build=#{platform.configure_build}",
                   "--host=#{platform.configure_host}",
                   "--disable-shared",
                   "--disable-nls",
                   "--with-bugurl=#{Build::BUG_URL}",
                   "--program-transform-name='s&^&#{arch.host}-&'"
                  ]

    # todo:
    build_binutils platform, arch, release, common_args, sysroot_dir, base_dir
    build_gcc      platform, arch, release, common_args, sysroot_dir, base_dir
    build_gdb      platform, arch, release, common_args, sysroot_dir, base_dir if params[:build_gdb]

    # strip executables
    if params[:strip_executables]
      build_env.clear
      self.system_ignore_result = true
      find_executables(install_dir, platform).each { |exe| system platform.strip, exe }
      self.system_ignore_result = false
    end
  end

  def build_binutils(platform, arch, release, cfg_args, sysroot_dir, base_dir)
    print "binutils"

    src_dir = File.join(Build::TOOLCHAIN_SRC_DIR, 'binutils', "binutils-#{Build::BINUTILS_VER}")
    build_dir = build_dir_for_component(base_dir, 'binutils')
    FileUtils.mkdir_p build_dir

    prepare_build_environment platform

    gmp_dir   = host_dep_dir(platform.name, 'gmp')
    isl_dir   = host_dep_dir(platform.name, release.version == '4.9' ? 'isl-old' : 'isl')
    cloog_dir = host_dep_dir(platform.name, release.version == '4.9' ? 'cloog-old' : 'cloog')

    build_env['CXXFLAGS'] += ' -std=gnu++98' if (platform.target_os == 'darwin' and platform.cross_compile?) # gcc 6.0

    args = cfg_args + binutils_arch_args(arch) + binutils_libstdcxx_args(platform) +
           ["--disable-werror",
            "--with-cloog=#{cloog_dir}",
            "--with-isl=#{isl_dir}",
            "--with-gmp=#{gmp_dir}",
            "--disable-isl-version-check",
            "--disable-cloog-version-check",
            "--enable-plugins",
            "--with-sysroot=#{sysroot_dir}"
           ]

    FileUtils.cd(build_dir) do
      system "#{src_dir}/configure", *args
      system 'make', '-j', num_jobs
      system 'make', 'install'
    end
  end

  def build_gcc(platform, arch, release, cfg_args, sysroot_dir, base_dir)
    print ", gcc"
    src_dir = File.join(Build::TOOLCHAIN_SRC_DIR, 'gcc', "gcc-#{release.version}")
    build_dir = build_dir_for_component(base_dir, 'gcc')
    FileUtils.mkdir_p build_dir

    prepare_build_environment platform

    build_env['CFLAGS'] += ' -static-libgcc -static-libstdc++'
    export_target_binutils install_dir(base_dir), arch
    cflags_for_target = '-O2 -Os -g -DTARGET_POSIX_IO -fno-short-enums'
    cxxflags_for_target = cflags_for_target
    case arch.name
    when 'x86', 'x86_64'
      cflags_for_target += ' -fPIC'
    end
    build_env['CFLAGS_FOR_TARGET']   = cflags_for_target
    build_env['CXXFLAGS_FOR_TARGET'] = cxxflags_for_target

    build_target   = ''
    install_target = 'install'
    if canadian_build? platform
      # expr.c:(.text+0x2708): undefined reference to `__udivdi3'
      if platform.name == 'windows'
        build_env['CFLAGS_FOR_BUILD']   = ' -m32'
        build_env['CXXFLAGS_FOR_BUILD'] = ' -m32'
      end
      build_env['PATH'] = "#{File.join(base_dir, 'host', 'install', 'bin')}:#{build_env['PATH']}"
      # When building canadian cross toolchain we cannot build GCC target libraries.
      # So we build the compilers only and copy the target libraries from
      # '...host/install' directory
      build_target   = 'all-gcc'
      install_target = 'install-gcc'
    end

    mpc_dir   = host_dep_dir(platform.name, 'mpc')
    mpfr_dir  = host_dep_dir(platform.name, 'mpfr')
    gmp_dir   = host_dep_dir(platform.name, 'gmp')
    isl_dir   = host_dep_dir(platform.name, release.version == '4.9' ? 'isl-old' : 'isl')
    cloog_dir = host_dep_dir(platform.name, release.version == '4.9' ? 'cloog-old' : 'cloog')

    args = cfg_args + gcc_arch_args(arch) + gcc_libstdcxx_args(platform) +
           ["--with-gnu-as",
            "--with-gnu-ld",
            "--with-mpc=#{mpc_dir}",
            "--with-mpfr=#{mpfr_dir}",
            "--with-gmp=#{gmp_dir}",
            "--with-cloog=#{cloog_dir}",
            "--with-isl=#{isl_dir}",
            "--disable-isl-version-check",
            "--disable-cloog-version-check",
            "--disable-libssp",
            "--disable-libmudflap",
	    "--disable-libstdc__-v3",
            "--disable-sjlj-exceptions",
	    "--disable-tls",
            "--disable-libitm",
            "--disable-libobjc",
            "--disable-bootstrap",
            "--enable-initfini-array",
            "--enable-libgomp",
            "--enable-gnu-indirect-function",
            "--enable-threads",
            "--disable-libsanitizer",
            "--enable-graphite=yes",
            "--enable-eh-frame-hdr-for-static",
            "--enable-languages=c,c++,objc,obj-c++",
            "--with-sysroot=#{sysroot_dir}"
           ]

    args << '--disable-libcilkrts' if (release.version == '4.9') and (arch.name == 'x86' or arch.name == 'x86_64')

    FileUtils.cd(build_dir) do
      system "#{src_dir}/configure", *args
      system 'make', '-j', num_jobs, build_target
      system 'make', install_target
    end

    install_dir = install_dir(base_dir)
    if canadian_build? platform
      host_libgcc_dir = File.join(base_dir, 'host', 'install', 'lib', 'gcc')
      libgcc_dir = File.join(install_dir, 'lib', 'gcc')
      FileUtils.mkdir_p libgcc_dir
      system 'rsync', '-a', "#{host_libgcc_dir}/", "#{libgcc_dir}/"
      #
      host_arch_lib_dir = File.join(base_dir, 'host', 'install', arch.host, 'lib')
      arch_lib_dir = File.join(install_dir, arch.host, 'lib')
      system 'rsync', '-a', "#{host_arch_lib_dir}/", "#{arch_lib_dir}/"
      #
      host_arch_lib64_dir = File.join(base_dir, 'host', 'install', arch.host, 'lib64')
      if Dir.exist? host_arch_lib64_dir
        arch_lib64_dir = File.join(install_dir, arch.host, 'lib64')
        system 'rsync', '-a', "#{host_arch_lib64_dir}/", "#{arch_lib64_dir}/"
      end
    end

    # remove unneeded files
    FileUtils.rm_rf [File.join(install_dir, 'share', 'man'), File.join(install_dir, 'share', 'info')]
    # todo: remove more files? see build-gcc.sh
  end

  def build_gdb(platform, arch, release, cfg_args, sysroot_dir, base_dir)
    print ", gdb"

    src_dir = File.join(Build::TOOLCHAIN_SRC_DIR, 'gdb', "gdb-#{GDB_VER}")
    build_dir = build_dir_for_component(base_dir, 'gdb')
    FileUtils.mkdir_p build_dir

    prepare_build_environment platform

    expat_dir = host_dep_dir(platform.name, 'expat')

    if canadian_build? platform
      build_env['CC_FOR_BUILD'] = Platform.new(Global::PLATFORM_NAME).cc
    end

    args = cfg_args +
           ["--disable-werror",
            "--with-expat",
            "--with-libexpat-prefix=#{expat_dir}",
            "--with-python=#{Global::tools_dir(platform.name)}/bin/python-config.sh",
            "--with-sysroot=#{sysroot_dir}"
           ]

    FileUtils.cd(build_dir) do
      system "#{src_dir}/configure", *args
      system 'make', '-j', num_jobs
      system 'make', 'install'
    end

    build_gdb_stub platform, arch, File.join(install_dir(base_dir), 'bin') if platform.target_os == 'windows'
  end

  def binutils_arch_args(arch)
    case arch.name
    when 'arm64'
      ['--enable-gold', '--enable-ld=default']
    else
      ['--enable-gold=default']
    end
  end

  def binutils_libstdcxx_args(platform)
    case platform.target_os
    when 'darwin'
      ['--with-host-libstdcxx=\'-static-libgcc -static-libstdc++ -lm\'', '--with-gold-ldflags=\'-static-libgcc -static-libstdc++\'']
    when 'linux'
      ['--with-host-libstdcxx=\'-static-libgcc -Wl,-Bstatic,-lstdc++,-Bdynamic -lm\'', '--enable-install-libbfd']
    when 'windows'
      ['--with-host-libstdcxx=\'-static-libgcc -Wl,-Bstatic,-lstdc++,-Bdynamic -lm\'', '--enable-install-libbfd', '--with-gold-ldflags=\'-static-libgcc -static-libstdc++ -static\'']
    end
  end

  def export_target_binutils(install_dir, arch)
    binutils_dir = File.join(install_dir, arch.host, 'bin')
    ['as', 'ld', 'ar', 'nm', 'strip', 'ranlib', 'objdump', 'readelf'].each do |util|
      build_env["#{util.upcase}_FOR_TARGET"] = File.join(binutils_dir, util)
    end
  end

  def gcc_arch_args(arch)
    case arch.name
    when 'x86'
      ['--with-arch=i686', '--with-tune=intel', '--with-fpmath=sse']
    when 'x86_64'
      ['--with-arch=x86-64', '--with-tune=intel', '--with-fpmath=sse', '--with-multilib-list=m32,m64,mx32']
    when 'arm'
      ['--with-float=soft', '--with-fpu=vfp', '--with-arch=armv5te', '--enable-target-optspace']
    when 'arm64'
      ['--enable-fix-cortex-a53-835769', '--enable-fix-cortex-a53-843419']
    else
      []
    end
  end

  def gcc_libstdcxx_args(platform)
    # link to the static C++ runtime to avoid depending on the host version
    case platform.target_os
    when 'darwin'
      ['--with-host-libstdcxx=\'-static-libgcc -lstdc++ -lm\'']
    when 'windows'
      ['--with-host-libstdcxx=\'-static-libgcc -static-libstdc++ -lstdc++ -lm -static\'']
    else
      ['--with-host-libstdcxx=\'-static-libgcc -Wl,-Bstatic,-lstdc++,-Bdynamic -lm\'']
    end
  end

  def build_gdb_stub(platform, arch, gdb_dir)
    gdb_exe = "#{arch.host}-gdb.exe"
    gdb_path = File.join(gdb_dir, gdb_exe)
    FileUtils.cp gdb_path, File.join(gdb_dir, "#{arch.host}-gdb-orig.exe")

    gdb_to_python_rel_dir = '..\\..\\..\\..\\..\\prebuilt\\windows-x86_64\\bin'
    pythonhome_rel_dir    = '..\\..\\..\\..\\..\\prebuilt\\windows-x86_64'

    gdb_stub_c = File.join(Build::NDK_SRC_DIR, 'sources', 'host-tools', 'gdb-stub', 'gdb-stub.c')

    args = platform.cflags.split(' ') +
           ['-O2',
            '-s',
            '-DNDEBUG',
            "-DGDB_TO_PYTHON_REL_DIR=\'\"#{gdb_to_python_rel_dir}\"\'",
            "-DPYTHONHOME_REL_DIR=\'\"#{pythonhome_rel_dir}\"\'",
            "-DGDB_EXECUTABLE_ORIG_FILENAME=\'\"#{gdb_exe}\"\'"
           ]

    system platform.cc, gdb_stub_c, '-o', gdb_path, *args
  end

  def prepare_build_environment(platform)
    build_env.clear
    build_env['PATH']   = "#{platform.toolchain_path}:#{Build.path}"
    build_env['CC']     = platform.cc
    build_env['CXX']    = platform.cxx
    build_env['AR']     = platform.ar
    build_env['RANLIB'] = platform.ranlib
    build_env['CFLAGS'] = platform.cflags + ' -O2 -s -Wno-error'
    # todo: do we need '-s' option?
    #build_env['CFLAGS']  += ' -s' if platform.compiler_major_version < 6

    if platform.target_os == 'windows'
      build_env['CFLAGS'] += ' -D__USE_MINGW_ANSI_STDIO=1'
      build_env['RC']      = platform.windres
      build_env['CFLAGS'] += ' -m32' if platform.target_cpu == 'x86'
    end

    build_env['CXXFLAGS'] = build_env['CFLAGS']

    build_env['MACOSX_DEPLOYMENT_TARGET'] = Build::MACOS_MIN_VER if platform.target_os == 'darwin'
  end

  # here we do what ./build/tools/gen-platforms.sh --minimal does
  def copy_sysroot(arch, dst)
    dst += '/usr'
    FileUtils.mkdir_p dst
    Build::API_LEVELS.select{ |l| l <= arch.min_api_level }.each do |api|
      src = File.join(Build::PLATFORM_DEVELOPMENT_DIR, 'ndk', 'platforms', "android-#{api}")
      FileUtils.cp_r "#{src}/include", dst
      arch_incs = "#{src}/arch-#{arch.name}/include"
      FileUtils.cp_r arch_incs, dst if Dir.exists? arch_incs
      generate_api_level api, dst if api == arch.min_api_level
      bootstrap_dir = "#{src}/arch-#{arch.name}/lib-bootstrap"
      if Dir.exists? bootstrap_dir
        sysroot_lib_dirs(arch).each do |d|
        libdir = File.join(dst, d)
        FileUtils.mkdir_p libdir
        s = "#{bootstrap_dir}/#{d}"
        if Dir.exists? s
          FileUtils.cp_r Dir["#{s}/*"], libdir
        else
          FileUtils.cp_r Dir["#{bootstrap_dir}/*.*o"], libdir
        end
        ['libcrystax.a', 'libstdc++.a', 'libm.a'].each { |lib| FileUtils.cp "#{Build::NDK_SRC_DIR}/sources/crystax/empty/libcrystax.a", "#{libdir}/#{lib}" }
        end
      end
    end
  end

  def generate_api_level(api, dir)
    File.open("#{dir}/include/android/api-level.h", 'w') do |f|
      f.puts "/*"
      f.puts " * Copyright (C) 2008 The Android Open Source Project"
      f.puts " * All rights reserved."
      f.puts " *"
      f.puts " * Redistribution and use in source and binary forms, with or without"
      f.puts " * modification, are permitted provided that the following conditions"
      f.puts " * are met:"
      f.puts " *  * Redistributions of source code must retain the above copyright"
      f.puts " *    notice, this list of conditions and the following disclaimer."
      f.puts " *  * Redistributions in binary form must reproduce the above copyright"
      f.puts " *    notice, this list of conditions and the following disclaimer in"
      f.puts " *    the documentation and/or other materials provided with the"
      f.puts " *    distribution."
      f.puts " *"
      f.puts " * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS"
      f.puts " * \"AS IS\" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT"
      f.puts " * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS"
      f.puts " * FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE"
      f.puts " * COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,"
      f.puts " * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,"
      f.puts " * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS"
      f.puts " * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED"
      f.puts " * AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,"
      f.puts " * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT"
      f.puts " * OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF"
      f.puts " * SUCH DAMAGE."
      f.puts " */"
      f.puts "#ifndef ANDROID_API_LEVEL_H"
      f.puts "#define ANDROID_API_LEVEL_H"
      f.puts ""
      f.puts "#define __ANDROID_API__ #{api}"
      f.puts ""
      f.puts "#endif /* ANDROID_API_LEVEL_H */"
    end
  end

  def sysroot_lib_dirs(arch)
    case arch.name
    when 'x86_64'
      ['lib', 'lib64', 'libx32']
    else
      ['lib']
    end
  end

  def create_libgccunwind(platform, arch, base_dir)
    base_dir = File.join(base_dir, 'host') if canadian_build? platform
    ar = File.join(build_dir_for_component(base_dir, 'binutils'), 'binutils', 'ar')
    arch.abis.each do |abi|
      unwind_lib = File.join(base_dir_for_platform(platform.name), UNWIND_SUB_DIR, abi, 'libgccunwind.a')
      gcc_dir = File.join(build_dir_for_component(base_dir, 'gcc'), arch.host)
      unwind_objs = unwind_objs_for_abi(abi, gcc_dir)
      FileUtils.mkdir_p File.dirname(unwind_lib)
      system ar, 'crsD', unwind_lib, *unwind_objs
    end
  end

  def unwind_objs_for_abi(abi, gcc_dir)
    case abi
    when 'armeabi-v7a'
      base_dir = "#{gcc_dir}/armv7-a/libgcc"
      objs = ['unwind-arm.o', 'libunwind.o', 'pr-support.o', 'unwind-c.o']
    when 'armeabi-v7a-hard'
      base_dir="#{gcc_dir}/armv7-a/hard/libgcc"
      objs = ['unwind-arm.o', 'libunwind.o', 'pr-support.o', 'unwind-c.o']
    when 'x86'
      base_dir = "#{gcc_dir}/libgcc"
      objs = ['unwind-c.o', 'unwind-dw2-fde-dip.o', 'unwind-dw2.o']
    when 'arm64-v8a', 'x86_64'
      base_dir = "#{gcc_dir}/libgcc"
      objs = ['unwind-c.o', 'unwind-dw2-fde-dip.o', 'unwind-dw2.o']
    end

    objs.map { |f| File.join base_dir, f }
  end

  def find_executables(dir, platform)
    if platform.target_os != 'windows'
      Dir["#{dir}/**/*"].select { |f| File.file?(f) and File.executable?(f) and !(f =~/.*gdb$/) }
    else
      Dir["#{dir}/**/*.exe"]
    end
  end

  def base_dir(platform, arch)
    File.join(build_base_dir, platform.name, arch.name)
  end

  def build_dir_for_component(base_dir, component)
    File.join base_dir, component
  end

  def install_dir(base_dir)
    File.join base_dir, 'install'
  end

  def build_log_file(base_dir)
    File.join base_dir, 'build.log'
  end

  def max_arch_name_len(arch_list)
    len = 0
    arch_list.each { |e| len = e.name.length if e.name.length > len }
    len
  end

  # this is a workaround
  # build command must check that build dependencies installed for all required platforms
  def update_host_dep_dirs(platform, host_platform)
    if @host_dep_dirs[host_platform.name].empty?
      @host_dep_dirs[platform.name].each_pair do |key, value|
        dir = value.gsub(platform.name, host_platform.name)
        raise "not exists required dependency directory: #{dir}" unless Dir.exist? dir
        dep = { key => dir }
        @host_dep_dirs[host_platform.name].update dep
      end
    end
  end
end
