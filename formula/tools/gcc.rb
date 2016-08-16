require_relative '../../library/toolchain.rb'

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


  # todo:
  #depends_on 'host/python'

  ARCHIVE_TOP_DIR  = 'toolchains'
  UNWIND_SUB_DIR   = 'sources/android/gccunwind/libs'
  LICENSES_SUB_DIR = 'build/instruments/toolchain-licenses'

  LICENSE_MASK = 'COPYING*'

  BINUTILS_VER = '2.25'
  GDB_VER      = '7.10'

  Lib = Struct.new(:name, :version, :url, :args, :templates)

  include Properties

  def install_archive(release, archive, platform_name = Global::PLATFORM_NAME, ndk_dir = Global::NDK_DIR)
    rel_dir = release_directory(release)
    FileUtils.mkdir_p rel_dir unless Dir.exists? rel_dir
    prop = get_properties(rel_dir)

    unwind_dir = File.join(Global::NDK_DIR, UNWIND_SUB_DIR)
    FileUtils.rm_rf unwind_dir if prop[:libunwind_installed]

    Build::ARCH_LIST.each do |arch|
      FileUtils.rm_rf File.join(Global::NDK_DIR, ARCHIVE_TOP_DIR, "#{arch.toolchain}-#{release.version}")
    end
    Utils.unpack archive, ndk_dir

    prop[:installed] = true
    prop[:installed_crystax_version] = release.crystax_version
    prop[:libunwind_installed] = Dir.exists? unwind_dir
    save_properties prop, rel_dir

    release.installed = release.crystax_version
  end

  def build(release, options, _host_dep_dirs, _target_dep_dirs)
    platforms = options.platforms.map { |name| Platform.new(name) }
    puts "Building #{name} #{release} for platforms: #{platforms.map{|a| a.name}.join(' ')}"

    self.num_jobs = options.num_jobs

    FileUtils.rm_rf build_base_dir

    puts "= preparing sources"
    libs = create_libs(release)

    platforms.each do |platform|
      puts "= building for #{platform.name}"
      build_libs libs, platform
      #[Build::ARCH_LIST[0]].each do |arch|
      Build::ARCH_LIST.each do |arch|
        self.log_file = build_log_file(platform, arch)
        puts  "  #{arch.name}: "
        build_toolchain platform, arch, release
      end

      if not options.build_only?
        pkg_dir = "#{base_dir_for_platform(platform)}/#{ARCHIVE_TOP_DIR}"
        #[Build::ARCH_LIST[0]].each do |arch|
        Build::ARCH_LIST.each do |arch|
          arch_pkg_dir = "#{pkg_dir}/#{arch.toolchain}-#{release.version}/prebuilt/#{platform.name}"
          FileUtils.mkdir_p arch_pkg_dir
          FileUtils.cd(install_dir_for_platform(platform, arch, release)) do
            FileUtils.cp  Dir[File.join(Global::NDK_DIR, LICENSES_SUB_DIR, 'COPYING*')], arch_pkg_dir
            FileUtils.cp_r [arch.host, 'bin', 'include', 'lib', 'libexec', 'share'], arch_pkg_dir
          end
          if Toolchain::DEFAULT_GCC.version != release.version
            puts  '  skipping libgccunwin for non-default gcc'
          else
            print '  unwind lib for abi: '
            create_libgccunwind platform, arch
          end
        end
        archive = File.join(Global::CACHE_DIR, archive_filename(release, platform.name))
        puts "= packaging #{archive}"
        dirs = [ARCHIVE_TOP_DIR]
        dirs << UNWIND_SUB_DIR.split('/')[0] if Toolchain::DEFAULT_GCC.version == release.version
        Utils.pack archive, base_dir_for_platform(platform), *dirs
      end

      if options.update_shasum?
        release.shasum = { platform.to_sym => Digest::SHA256.hexdigest(File.read(archive, mode: "rb")) }
        update_shasum release, platform
      end

      puts "= installing #{archive}"
      install_archive release, archive, platform.name unless options.build_only?
      FileUtils.rm_rf base_dir_for_platform(platform) unless options.no_clean?
    end

    if options.no_clean?
      puts "No cleanup, for build artifacts see #{build_base_dir}"
    else
      FileUtils.rm_rf build_base_dir
    end
  end

  def create_libs(release)
    if release.version == '4.9'
      isl_ver = '0.11.1'
      cloog_ver = '0.18.0'
    else
      isl_ver = '0.17.1'
      cloog_ver = '0.18.4'
    end

    libs = [Lib.new('gmp',
             '6.1.1',
             "https://gmplib.org/download/gmp/gmp-${version}.tar.xz",
             '',
             ["--prefix=${install_dir}",
              "--host=${host}",
              "--enable-cxx",
              "--disable-shared"
             ]),
     Lib.new('ppl',
             '1.2',
             "http://bugseng.com/products/ppl/download/ftp/releases/${version}/ppl-${version}.tar.xz",
             '',
             ["--prefix=${install_dir}",
              "--host=${host}",
              "--with-gmp=${install_dir}",
	      "--without-java",
	      "--disable-ppl_lcdd",
              "--disable-ppl_lpsol",
              "--disable-ppl_pips",
              "--disable-shared",
              "--disable-silent-rules",
              "--disable-documentation",
              "--with-sysroot"
             ]),
     Lib.new('isl',
             isl_ver,
             "http://isl.gforge.inria.fr/isl-${version}.tar.gz",
             '',
             ["--prefix=${install_dir}",
              "--host=${host}",
              "--with-gmp-prefix=${install_dir}",
              "--disable-shared",
              "--disable-silent-rules",
              "--with-sysroot"
             ]),
     Lib.new('cloog',
             cloog_ver,
             "https://www.bastoul.net/cloog/pages/download/cloog-${version}.tar.gz",
             '',
             ["--prefix=${install_dir}",
              "--host=${host}",
              "--with-isl=system",
              "--with-isl-prefix=${install_dir}",
              "--with-gmp=system",
              "--with-gmp-prefix=${install_dir}",
              "--disable-shared",
              "--disable-silent-rules",
              "--with-sysroot"
             ]),
     Lib.new('mpfr',
             '3.1.4',
             "https://mirrors.ocf.berkeley.edu/debian/pool/main/m/mpfr4/mpfr4_${version}.orig.tar.xz",
             '',
             ["--prefix=${install_dir}",
              "--host=${host}",
              "--with-gmp=${install_dir}",
              "--disable-shared",
              "--disable-silent-rules",
              "--with-sysroot"
             ]),
     Lib.new('mpc',
             '1.0.3',
             "https://ftpmirror.gnu.org/mpc/mpc-${version}.tar.gz",
             '',
             ["--prefix=${install_dir}",
              "--host=${host}",
              "--with-gmp=${install_dir}",
              "--with-mpfr=${install_dir}",
              "--disable-shared",
              "--disable-silent-rules",
              "--with-sysroot"
             ]),
     Lib.new('expat',
             '2.2.0',
             "https://downloads.sourceforge.net/project/expat/expat/${version}/expat-${version}.tar.bz2",
             '',
             ["--prefix=${install_dir}",
              "--host=${configure_host}",
              "--disable-shared"
             ])
    ]

    FileUtils.mkdir_p libs_src_dir
    libs.each do |lib|
      ver_url = lib.url.gsub('${version}', lib.version)
      archive = File.join(Global::CACHE_DIR, File.basename(URI.parse(ver_url).path))
      Utils.download ver_url, archive unless File.exists? archive
      Utils.unpack archive, libs_src_dir
      FileUtils.cd(libs_src_dir) { FileUtils.mv "#{lib.name}-#{lib.version}", lib.name }
    end

    libs
  end

  def build_libs(libs, platform)
    puts "  libraries: "
    base_dir = libs_base_dir(platform)
    install_dir = libs_install_dir(platform)
    FileUtils.mkdir_p [base_dir, install_dir]
    self.log_file = File.join(base_dir, 'build.log')

    print "    "
    prepare_build_environment platform
    libs.each.with_index do |lib, index|
      print lib.name

      lib.args = lib.templates.map do |template|
        arg = template.gsub('${install_dir}', install_dir)
        arg.gsub('${host}', platform.configure_host)
      end
      lib.args << 'ABI=32' if lib.name == 'gmp' and platform.target_name == 'windows'

      build_dir = File.join(base_dir, lib.name)
      FileUtils.mkdir_p build_dir
      FileUtils.cd(build_dir) do
        system "#{libs_src_dir}/#{lib.name}/configure", *lib.args
        system 'make', '-j', num_jobs
        system 'make', 'install'
      end
      FileUtils.cd(install_dir) { FileUtils.rm_rf ['bin', 'share', 'lib/pkgconfig'] + Dir['lib/*.la'] }

      print ", " if index + 1 < libs.count
    end
    puts ''
  end

  def build_toolchain(platform, arch, release)
    # prepare base dirs and log file
    base_dir = base_dir_for_platform_arch(platform, arch)
    install_dir = install_dir_for_platform(platform, arch, release)
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
                   "--with-bugurl=https://tracker.crystax.net/projects/ndk",
                   "--program-transform-name='s&^&#{arch.host}-&'"
                  ]

    build_binutils platform, arch, release, common_args, sysroot_dir
    build_gcc      platform, arch, release, common_args, sysroot_dir
    build_gdb      platform, arch, release, common_args, sysroot_dir

    # strip executables
    build_env.clear
    self.system_ignore_result = true
    find_executables(install_dir, platform).each { |exe| system platform.strip, exe }
    self.system_ignore_result = false
  end

  def build_binutils(platform, arch, release, cfg_args, sysroot_dir)
    print "    binutils"

    src_dir = File.join(Build::TOOLCHAIN_SRC_DIR, 'binutils', "binutils-#{BINUTILS_VER}")
    build_dir = build_dir_for_component(platform, arch, 'binutils')
    FileUtils.mkdir_p build_dir

    prepare_build_environment platform

    lid = libs_install_dir(platform)
    args = cfg_args + binutils_arch_args(arch) +
           ["--disable-werror",
            "--with-cloog=#{lid}",
            "--with-isl=#{lid}",
            "--with-gmp=#{lid}",
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

  def build_gcc(platform, arch, release, cfg_args, sysroot_dir)
    print ", gcc"
    src_dir = File.join(Build::TOOLCHAIN_SRC_DIR, 'gcc', "gcc-#{release.version}")
    build_dir = build_dir_for_component(platform, arch, 'gcc')
    FileUtils.mkdir_p build_dir

    prepare_build_environment platform
    build_env['CFLAGS'] += ' -static-libgcc -static-libstdc++'
    build_env['CFLAGS'] += ' -D__USE_MINGW_ANSI_STDIO=1' if platform.target_os == 'windows'
    export_target_binutils platform, release, arch
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

    # todo:
    #   "--with-gxx-include-dir=$TOOLCHAIN_BUILD_PREFIX/include/c++/$GCC_BASE_VERSION"
    lid = libs_install_dir(platform)
    args = cfg_args + gcc_arch_args(arch) + gcc_libstdcxx_args(platform) +
           ["--with-gnu-as",
            "--with-gnu-ld",
            "--with-mpc=#{lid}",
            "--with-mpfr=#{lid}",
            "--with-gmp=#{lid}",
            "--with-cloog=#{lid}",
            "--with-isl=#{lid}",
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
            "--disable-libsanitizer",
            "--enable-graphite=yes",
            "--enable-eh-frame-hdr-for-static",
            "--enable-languages=c,c++,objc,obj-c++",
            "--with-sysroot=#{sysroot_dir}"
           ]

    # todo: remove?
    #args << (Global::OS == 'darwin' ? '--disable-plugin' : '')
    args << '--disable-libcilkrts' if (release.version == '4.9') and (arch.name == 'x86' or arch.name == 'x86_64')

    FileUtils.cd(build_dir) do
      system "#{src_dir}/configure", *args
      system 'make', '-j', num_jobs
      system 'make', 'install'
    end

    # remove unneeded files
    install_dir = install_dir_for_platform(platform, arch, release)
    FileUtils.rm_rf [File.join(install_dir, 'share', 'man'), File.join(install_dir, 'share', 'info')]
    # todo: remove more files? see build-gcc.sh
  end

  def build_gdb(platform, arch, release, cfg_args, sysroot_dir)
    puts ", gdb"

    src_dir = File.join(Build::TOOLCHAIN_SRC_DIR, 'gdb', "gdb-#{GDB_VER}")
    build_dir = build_dir_for_component(platform, arch, 'gdb')
    FileUtils.mkdir_p build_dir

    prepare_build_environment platform

    args = cfg_args +
           ["--disable-werror",
            "--with-expat",
            "--with-libexpat-prefix=#{libs_install_dir(platform)}",
            "--with-python=#{Global::NDK_DIR}/prebuilt/#{Global::PLATFORM_NAME}/bin/python-config.sh",
            "--with-sysroot=#{sysroot_dir}"
           ]

    FileUtils.cd(build_dir) do
      system "#{src_dir}/configure", *args
      system 'make', '-j', num_jobs
      system 'make', 'install'
    end
  end

  def binutils_arch_args(arch)
    # gold
    case arch.name
    when 'mips', 'mips64'
      []
    when 'arm64'
      ['--enable-gold', '--enable-ld=default']
    else
      ['--enable-gold=default']
    end
  end

  def export_target_binutils(platform, release, arch)
    binutils_dir = File.join(install_dir_for_platform(platform, arch, release), arch.host, 'bin')
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
    if Global::OS == 'darwin'
      ['--with-host-libstdcxx=\'-static-libgcc -lstdc++ -lm\'']
    elsif platform.target_os == 'windows'
      ['--with-host-libstdcxx=\'-static-libgcc -static-libstdc++ -lstdc++ -lm -static\'']
    else
      ['--with-host-libstdcxx=\'-static-libgcc -Wl,-Bstatic,-lstdc++,-Bdynamic -lm\'']
    end
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

  def release_directory(release)
    File.join(Global::SERVICE_DIR, name, release.version)
  end

  def base_dir_for_platform_arch(platform, arch)
    File.join build_base_dir, platform.name, arch.name
  end

  def build_dir_for_component(platform, arch, component)
    File.join base_dir_for_platform_arch(platform, arch), component
  end

  def install_dir_for_platform(platform, arch, release)
    File.join base_dir_for_platform_arch(platform, arch), 'install', "#{arch.host}-#{release.version}"
  end

  def build_log_file(platform, arch)
    File.join base_dir_for_platform_arch(platform, arch), 'build.log'
  end

  def libs_src_dir
    File.join build_base_dir, 'src'
  end

  def libs_base_dir(platform)
    File.join base_dir_for_platform(platform), 'libs'
  end

  def libs_build_dir(platform)
    File.join libs_base_dir(platform), 'build'
  end

  def libs_install_dir(platform)
    File.join libs_base_dir(platform), 'install'
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

  def create_libgccunwind(platform, arch)
    arch.abis.each.with_index do |abi, index|
      print abi
      unwind_lib = File.join(base_dir_for_platform(platform), UNWIND_SUB_DIR, abi, 'libgccunwind.a')
      gcc_dir = File.join(build_dir_for_component(platform, arch, 'gcc'), arch.host)
      unwind_objs = unwind_objs_for_abi(abi, gcc_dir)
      FileUtils.mkdir_p File.dirname(unwind_lib)
      system binutil_for_arch(platform, arch, 'ar'), 'crsD', unwind_lib, *unwind_objs
      print ', ' if index + 1 < arch.abis.count
    end
    puts ''
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

  def binutil_for_arch(platform, arch, util)
    File.join(build_dir_for_component(platform, arch, 'binutils'), 'binutils', util)
  end

  def find_executables(dir, platform)
    if platform.target_os != 'windows'
      Dir["#{dir}/**/*"].select { |f| File.file?(f) and File.executable?(f) and !(f =~/.*gdb$/) }
    else
      Dir["#{dir}/**/*.exe"]
    end
  end
end
