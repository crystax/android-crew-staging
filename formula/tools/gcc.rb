class Gcc < Tool

  desc "GCC-based toolchain"
  homepage "https://gcc.gnu.org"
  url "toolchain/gcc"

  release version: '4.9', crystax_version: 1, sha256: { linux_x86_64:   '0',
                                                        darwin_x86_64:  '0',
                                                        windows_x86_64: '0',
                                                        windows:        '0'
                                                      }

  release version: '5', crystax_version: 1, sha256: { linux_x86_64:   '0',
                                                      darwin_x86_64:  '0',
                                                      windows_x86_64: '0',
                                                      windows:        '0'
                                                    }

  release version: '6', crystax_version: 1, sha256: { linux_x86_64:   '0',
                                                      darwin_x86_64:  '0',
                                                      windows_x86_64: '0',
                                                      windows:        '0'
                                                    }

  build_depends_on 'gmp'
  build_depends_on 'isl'
  build_depends_on 'ppl'
  build_depends_on 'mpc'
  build_depends_on 'mpfr'
  build_depends_on 'cloog'
  build_depends_on 'expat'
  build_depends_on 'isl-old'
  build_depends_on 'cloog-old'
  build_depends_on 'python', ns: 'host'

  ARCHIVE_TOP_DIR  = 'toolchains'
  UNWIND_SUB_DIR   = 'sources/android/gccunwind/libs'
  LICENSES_SUB_DIR = 'build/instruments/toolchain-licenses'

  LICENSE_MASK = 'COPYING*'

  GDB_VER      = '7.10'

  Lib = Struct.new(:name, :version, :url, :args, :templates)

  def install_archive(release, archive, platform_name = Global::PLATFORM_NAME, ndk_dir = Global::NDK_DIR)
    rel_dir = release_directory(release)
    FileUtils.mkdir_p rel_dir unless Dir.exists? rel_dir
    prop = get_properties(rel_dir)

    unwind_dir = File.join(Global::NDK_DIR, UNWIND_SUB_DIR)
    FileUtils.rm_rf unwind_dir if prop[:libunwind_installed]

    Build::ARCH_LIST.each do |arch|
      FileUtils.rm_rf File.join(Global::NDK_DIR, ARCHIVE_TOP_DIR, "#{arch.toolchain}-#{release.version}", 'prebuilt', platform_name)
    end
    Utils.unpack archive, ndk_dir

    prop[:installed] = true
    prop[:installed_crystax_version] = release.crystax_version
    prop[:libunwind_installed] = Dir.exists? unwind_dir
    save_properties prop, rel_dir

    release.installed = release.crystax_version
  end

  def build(release, options, host_dep_dirs, _target_dep_dirs)
    platforms = options.platforms.map { |name| Platform.new(name) }
    puts "Building #{name} #{release} for platforms: #{platforms.map{|a| a.name}.join(' ')}"

    self.num_jobs = options.num_jobs

    FileUtils.rm_rf build_base_dir

    platforms.each do |platform|
      puts "= building for #{platform.name}"
      #[Build::ARCH_LIST[0]].each do |arch|
      Build::ARCH_LIST.each do |arch|
        base_dir = base_dir(platform, arch)
        self.log_file = build_log_file(base_dir)
        printf  "  %-#{max_arch_name_len+1}s ", "#{arch.name}:"
        if platform.target_os == 'windows'
          # when building widows based toolchain we must at first build toolchain
          # that targets the same arch and works on the host we're building on
          host_platform = Platform.new(Global::PLATFORM_NAME)
          update_dep_dirs(host_dep_dirs, platform, host_platform)
          build_toolchain host_platform, arch, release, host_dep_dirs, File.join(base_dir, 'host'), build_gdb: false
          print '   '
        end
        build_toolchain platform, arch, release, host_dep_dirs, base_dir
        puts ""
      end

      if not options.build_only?
        pkg_dir = File.join(build_base_dir, platform.name, ARCHIVE_TOP_DIR)
        #[Build::ARCH_LIST[0]].each do |arch|
        Build::ARCH_LIST.each do |arch|
          base_dir = base_dir(platform, arch)
          arch_pkg_dir = File.join(pkg_dir, "#{arch.toolchain}-#{release.version}", 'prebuilt', platform.name)
          FileUtils.mkdir_p arch_pkg_dir
          FileUtils.cd(install_dir(base_dir)) do
            FileUtils.cp  Dir[File.join(Global::NDK_DIR, LICENSES_SUB_DIR, 'COPYING*')], arch_pkg_dir
            FileUtils.cp_r [arch.host, 'bin', 'include', 'lib', 'libexec', 'share'], arch_pkg_dir
          end
          create_libgccunwind platform, arch, base_dir if Toolchain::DEFAULT_GCC.version == release.version
        end

        archive = cache_file(release, platform.name)
        puts "= packaging #{archive}"
        dirs = [ARCHIVE_TOP_DIR]
        dirs << UNWIND_SUB_DIR.split('/')[0] if Toolchain::DEFAULT_GCC.version == release.version
        Utils.pack archive, base_dir_for_platform(platform), *dirs

        if options.update_shasum?
          release.shasum = { platform.to_sym => Digest::SHA256.hexdigest(File.read(archive, mode: "rb")) }
          update_shasum release, platform
        end

        puts "= installing #{archive}"
        install_archive release, archive, platform.name
      end

      FileUtils.rm_rf base_dir_for_platform(platform) unless options.no_clean?
    end

    if options.no_clean?
      puts "No cleanup, for build artifacts see #{build_base_dir}"
    else
      FileUtils.rm_rf build_base_dir
    end
  end

  private

  def build_toolchain(platform, arch, release, host_dep_dirs, base_dir, params = { build_gdb: true })
    # prepare base dirs and log file
    install_dir = install_dir(base_dir)
    FileUtils.mkdir_p install_dir

    # copy sysroot
    sysroot_dir = File.join(install_dir, 'sysroot')
    copy_sysroot arch, sysroot_dir

    common_args = ["--prefix=#{install_dir}",
                   "--target=#{arch.host}",
                   "--build=#{platform.toolchain_build}",
                   "--host=#{platform.toolchain_host}",
                   "--disable-shared",
                   "--disable-nls",
                   "--with-bugurl=#{Build::BUG_URL}",
                   "--program-transform-name='s&^&#{arch.host}-&'"
                  ]

    build_binutils platform, arch, release, host_dep_dirs, common_args, sysroot_dir, base_dir
    build_gcc      platform, arch, release, host_dep_dirs, common_args, sysroot_dir, base_dir
    build_gdb      platform, arch, release, host_dep_dirs, common_args, sysroot_dir, base_dir if params[:build_gdb]

    # strip executables
    build_env.clear
    self.system_ignore_result = true
    find_executables(install_dir, platform).each { |exe| system platform.strip, exe }
    self.system_ignore_result = false
  end

  def build_binutils(platform, arch, release, host_dep_dirs, cfg_args, sysroot_dir, base_dir)
    print "binutils"

    src_dir = File.join(Build::TOOLCHAIN_SRC_DIR, 'binutils', "binutils-#{Build::BINUTILS_VER}")
    build_dir = build_dir_for_component(base_dir, 'binutils')
    FileUtils.mkdir_p build_dir

    prepare_build_environment platform

    gmp_dir   = host_dep_dirs[platform.name]['gmp']
    isl_dir   = host_dep_dirs[platform.name][release.version == '4.9' ? 'isl-old' : 'isl']
    cloog_dir = host_dep_dirs[platform.name][release.version == '4.9' ? 'cloog-old' : 'cloog']

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

  def build_gcc(platform, arch, release, host_dep_dirs, cfg_args, sysroot_dir, base_dir)
    print ", gcc"
    src_dir = File.join(Build::TOOLCHAIN_SRC_DIR, 'gcc', "gcc-#{release.version}")
    build_dir = build_dir_for_component(base_dir, 'gcc')
    FileUtils.mkdir_p build_dir

    prepare_build_environment platform
    build_env['CFLAGS'] += ' -static-libgcc -static-libstdc++'
    build_env['CFLAGS'] += ' -D__USE_MINGW_ANSI_STDIO=1' if platform.target_os == 'windows'
    export_target_binutils install_dir(base_dir), arch
    cflags_for_target = '-O2 -Os -g -DTARGET_POSIX_IO -fno-short-enums'
    cxxflags_for_target = cflags_for_target
    case arch.name
    when 'x86', 'x86_64'
      cflags_for_target += ' -fPIC'
    when 'mips', 'mips64'
      cflags_for_target += ' -fexceptions -fpic'
      cxxflags_for_target += ' -frtti -fpic'
    end
    build_env['CFLAGS_FOR_TARGET']   = cflags_for_target
    build_env['CXXFLAGS_FOR_TARGET'] = cxxflags_for_target

    build_target   = ''
    install_target = 'install'
    if platform.target_os == 'windows'
      if platform.target_cpu == 'x86'
        build_env['CFLAGS_FOR_BUILD']  = ' -m32'
        build_env['CXXFLAGS_FOR_BUILD'] = ' -m32'
      end
      build_env['PATH'] = "#{File.join(base_dir, 'host', 'install', 'bin')}:#{ENV['PATH']}"
      # When building canadian cross toolchain we cannot build GCC target libraries.
      # So we build the compilers only and copy the target libraries from
      # '...host/install' directory
      build_target   = 'all-gcc'
      install_target = 'install-gcc'
    end

    mpc_dir   = host_dep_dirs[platform.name]['mpc']
    mpfr_dir  = host_dep_dirs[platform.name]['mpfr']
    gmp_dir   = host_dep_dirs[platform.name]['gmp']
    isl_dir   = host_dep_dirs[platform.name][release.version == '4.9' ? 'isl-old' : 'isl']
    cloog_dir = host_dep_dirs[platform.name][release.version == '4.9' ? 'cloog-old' : 'cloog']

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
      #system 'make', build_target
      system 'make', install_target
    end

    install_dir = install_dir(base_dir)
    if platform.target_os == 'windows'
      libgcc_dir = File.join(install_dir, 'lib', 'gcc')
      FileUtils.mkdir_p libgcc_dir
      host_libgcc_dir = File.join(base_dir, 'host', 'install', 'lib', 'gcc')
      system 'rsync', '-a', "#{host_libgcc_dir}/", "#{libgcc_dir}/"
    end

    # remove unneeded files
    FileUtils.rm_rf [File.join(install_dir, 'share', 'man'), File.join(install_dir, 'share', 'info')]
    # todo: remove more files? see build-gcc.sh
  end

  def build_gdb(platform, arch, release, host_dep_dirs, cfg_args, sysroot_dir, base_dir)
    print ", gdb"

    src_dir = File.join(Build::TOOLCHAIN_SRC_DIR, 'gdb', "gdb-#{GDB_VER}")
    build_dir = build_dir_for_component(base_dir, 'gdb')
    FileUtils.mkdir_p build_dir

    prepare_build_environment platform

    expat_dir = host_dep_dirs[platform.name]['expat']

    if platform.target_os == 'windows'
      build_env['CC_FOR_BUILD'] = Platform.new(Global::PLATFORM_NAME).cc
    end

    args = cfg_args +
           ["--disable-werror",
            "--with-expat",
            "--with-libexpat-prefix=#{expat_dir}",
            "--with-python=#{Utility.active_dir('python', Global::engine_dir(platform.name))}/python-config.sh",
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
    when 'mips', 'mips64'
      []
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
    when 'mips'
      ['--with-arch=mips32', '--disable-fixed-point']
    when 'mips64'
      ['--with-arch=mips64r6', '--disable-fixed-point']
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

    gdb_stub_c = File.join(Global::NDK_DIR, 'sources', 'host-tools', 'gdb-stub', 'gdb-stub.c')

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
    build_env['LANG']     = 'C'
    build_env['CC']       = platform.cc
    build_env['CXX']      = platform.cxx
    build_env['AR']       = platform.ar
    build_env['RANLIB']   = platform.ranlib
    build_env['CFLAGS']   = platform.cflags + ' -O2 -s -Wno-error'
    build_env['CXXFLAGS'] = platform.cxxflags
    if platform.target_os == 'windows'
      build_env['CFLAGS'] += ' -D__USE_MINGW_ANSI_STDIO=1'
      build_env['PATH'] = "#{File.dirname(platform.cc)}:#{ENV['PATH']}"
      build_env['RC'] = "x86_64-w64-mingw32-windres -F pe-i386" if platform.target_cpu == 'x86'
    end
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
        ['libcrystax.a', 'libstdc++.a', 'libm.a'].each { |lib| FileUtils.cp "#{Global::NDK_DIR}/sources/crystax/empty/libcrystax.a", "#{libdir}/#{lib}" }
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
    when 'mips64'
      ['lib', 'libr2', 'libr6', 'lib64r2', 'lib64']
    when 'mips'
      ['lib', 'libr2', 'libr6']
    else
      ['lib']
    end
  end

  def create_libgccunwind(platform, arch, base_dir)
    base_dir = File.join(base_dir, 'host') if platform.target_os == 'windows'
    ar = File.join(build_dir_for_component(base_dir, 'binutils'), 'binutils', 'ar')
    arch.abis.each do |abi|
      unwind_lib = File.join(base_dir_for_platform(platform), UNWIND_SUB_DIR, abi, 'libgccunwind.a')
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
    when 'x86', 'mips'
      base_dir = "#{gcc_dir}/libgcc"
      objs = ['unwind-c.o', 'unwind-dw2-fde-dip.o', 'unwind-dw2.o']
    when 'arm64-v8a', 'x86_64', 'mips64'
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

  def max_arch_name_len()
    len = 0
    Build::ARCH_LIST.each { |arch| len = arch.name.size if arch.name.size > len }
    len
  end

  def update_dep_dirs(dep_dirs, platform, host_platform)
    if dep_dirs[host_platform.name].empty?
      dep_dirs[platform.name].each_pair do |key, value|
        dir = value.gsub(platform.name, host_platform.name)
        raise "not exists required dependency directory: #{dir}" unless Dir.exist? dir
        dep = { key => dir }
        dep_dirs[host_platform.name].update dep
      end
    end
  end
end
