class Platforms < BasePackage

  desc "Android platforms headers and libraries"
  # todo:
  #homepage ""
  #url "https://www.cs.princeton.edu/~bwk/btl.mirror/awk.tar.gz"

  release version: '24', crystax_version: 1, sha256: '0'

  # todo:
  #build_depends_on 'libcrystax'
  #build_depends_on default_compiler

  ARCHIVE_TOP_DIRS  = ['platforms']  # todo: , 'samples']

  attr_accessor :src_dir, :install_dir

  # todo: move method to the BasePackage class
  def install_archive(release, archive, ndk_dir = Global::NDK_DIR)
    rel_dir = release_directory(release)
    FileUtils.mkdir_p rel_dir unless Dir.exists? rel_dir
    prop = get_properties(rel_dir)

    FileUtils.rm_rf ARCHIVE_TOP_DIRS.map { |d| File.join Global::NDK_DIR, d }
    Utils.unpack archive, ndk_dir

    prop[:installed] = true
    prop[:installed_crystax_version] = release.crystax_version
    save_properties prop, rel_dir

    release.installed = release.crystax_version
  end

  def build(release, options, host_dep_dirs, _target_dep_dirs)
    puts "Building #{name} #{release} for all platforms"

    FileUtils.rm_rf build_base_dir

    build_env['TMPDIR'] = ENV['TMPDIR'] = Build::BASE_BUILD_DIR

    self.src_dir = File.join(Build::PLATFORM_DEVELOPMENT_DIR, 'ndk')
    self.install_dir = File.join(build_base_dir, 'install')
    FileUtils.mkdir_p install_dir

    self.log_file = build_log_file

    copy_api_level_sysroot
    # todo:
    #copy_samples
    patch_sysroot_header_and_libraries

    puts "= cleaning sysroot"
    FileUtils.cd(install_dir) { FileUtils.rm Dir['platforms/**/libcrystax.*'] }

    return if options.build_only?

    archive = cache_file(release)
    puts "= packaging #{archive}"
    Utils.pack archive, install_dir, *ARCHIVE_TOP_DIRS

    if options.update_shasum?
      release.shasum = { platform.to_sym => Digest::SHA256.hexdigest(File.read(archive, mode: "rb")) }
      update_shasum release, platform
    end

    if options.install?
      puts "= installing #{archive}"
      install_archive release, archive
    end

    FileUtils.rm_rf build_base_dir unless options.no_clean?
  end

  def copy_api_level_sysroot
    Build::ARCH_LIST.each do |arch|
      puts "= generating arch: #{arch.name}"
      # Find first platform for this arch
      prev_sysroot_dst = nil
      prev_platform_src_arch = nil
      lib_dir = arch.default_lib_dir

      Build::API_LEVELS.each do |api_level|
        #puts "  generating platform: #{api_level}"
        platform_dst = "platforms/android-#{api_level}"   # Relative to $DSTDIR
        platform_src = platform_dst                       # Relative to $SRCDIR
        sysroot_dst = "#{platform_dst}/arch-#{arch}/usr"
        # Skip over if there is no arch-specific file for this platform
        # and no destination platform directory was created. This is needed
        # because x86 and MIPS don't have files for API levels 3-8.
        next if !prev_sysroot_dst and !File.directory?("#{src_dir}/#{platform_src}/arch-#{arch}")

        #puts "    populating platforms/android-#{api_level}/arch-#{arch}"

        if prev_sysroot_dst
          # If this is not the first destination directory, copy over the files from the previous one now.
          #log "Copying \$DST/$PREV_SYSROOT_DST to \$DST/$SYSROOT_DST"
          #copy_directory "$DSTDIR/$PREV_SYSROOT_DST" "$DSTDIR/$SYSROOT_DST"
          FileUtils.cd(install_dir) do
            FileUtils.mkdir_p File.dirname(sysroot_dst)
            FileUtils.cp_r prev_sysroot_dst, File.dirname(sysroot_dst)
          end
        else
          # If this is the first destination directory, copy the common
          # files from previous platform directories into this one.
          # This helps copy the common headers from android-3 to android-8
          # into the x86 and mips android-9 directories.
          Build::API_LEVELS.each do |old_api_level|
            break if old_api_level == api_level
            copy_src_directory "platforms/android-#{old_api_level}/include", "#{sysroot_dst}/include"   # common android-#{old_api_level} headers
          end
        end

        # There are two set of bionic headers: the original ones haven't been updated since
        # gingerbread except for bug fixing, and the new ones in android-$FIRST_API64_LEVEL
        # with 64-bit support.  Before the old bionic headers are deprecated/removed, we need
        # to remove stale old headers when createing platform = $FIRST_API64_LEVEL
        if api_level == MIN_64_API_LEVEL
          nonbionic_files = %w{ android EGL GLES GLES2 GLES3 KHR media OMXAL SLES jni.h thread_db.h zconf.h zlib.h }
          dir = "#{install_dir}/#{sysroot_dst}/include"
          if File.directory? dir
            FileUtils.cd(dir) do
              Dir['*'].each { |file| FileUtils.rm_rf file unless nonbionic_files.include?(file) }
            end
          end
        end

        # Now copy over all non-arch specific include files
        copy_src_directory "#{platform_src}/include",              "#{sysroot_dst}/include"         # common system headers
        copy_src_directory "#{platform_src}/arch-#{arch}/include", "#{sysroot_dst}/include"         # ARCH system headers

        generate_api_level api_level, arch

        # Copy the prebuilt static libraries.  We need full set for multilib compiler for some arch
        case arch.name
        when 'x86_64'
          copy_src_directory "#{platform_src}/arch-#{arch}/lib",    "#{sysroot_dst}/lib"             # x86 sysroot libs
          copy_src_directory "#{platform_src}/arch-#{arch}/lib64",  "#{sysroot_dst}/lib64"           # x86_64 sysroot libs
          copy_src_directory "#{platform_src}/arch-#{arch}/libx32", "#{sysroot_dst}/libx32"          # x32 sysroot libs
        when 'mips64'
          copy_src_directory "#{platform_src}/arch-#{arch}/lib",     "#{sysroot_dst}/lib"            # mips -mabi=32 -mips32 sysroot libs
          copy_src_directory "#{platform_src}/arch-#{arch}/libr2",   "#{sysroot_dst}/libr2"          # mips -mabi=32 -mips32r2 sysroot libs
          copy_src_directory "#{platform_src}/arch-#{arch}/libr6",   "#{sysroot_dst}/libr6"          # mips -mabi=32 -mips32r6 sysroot libs
          copy_src_directory "#{platform_src}/arch-#{arch}/lib64r2", "#{sysroot_dst}/lib64r2"        # mips -mabi=64 -mips64r2 sysroot libs
          copy_src_directory "#{platform_src}/arch-#{arch}/lib64",   "#{sysroot_dst}/lib64"          # mips -mabi=64 -mips64r6 sysroot libs
        when 'mips'
          copy_src_directory "#{platform_src}/arch-#{arch}/lib",   "#{sysroot_dst}/lib"              # mips -mabi=32 -mips32 sysroot libs
          copy_src_directory "#{platform_src}/arch-#{arch}/libr2", "#{sysroot_dst}/libr2"            # mips -mabi=32 -mips32r2 sysroot libs
          copy_src_directory "#{platform_src}/arch-#{arch}/libr6", "#{sysroot_dst}/libr6"            # mips -mabi=32 -mips32r6 sysroot libs
        else
          copy_src_directory "#{platform_src}/arch-#{arch}/#{lib_dir}", "#{sysroot_dst}/#{lib_dir}"  # $ARCH sysroot libs
        end

        # Generate C runtime object files when available
        platform_src_arch = "#{platform_src}/arch-#{arch}/src"
        if File.directory? "#{src_dir}/#{platform_src_arch}"
          prev_platform_src_arch = platform_src_arch
        else
          platform_src_arch = prev_platform_src_arch
        end

        # Genreate crt objects
        case arch.name
        when 'x86_64'
          gen_crt_objects api_level, arch, "platforms/common/src", platform_src_arch, "#{sysroot_dst}/lib",    "-m32"
          gen_crt_objects api_level, arch, "platforms/common/src", platform_src_arch, "#{sysroot_dst}/lib64",  "-m64"
          gen_crt_objects api_level, arch, "platforms/common/src", platform_src_arch, "#{sysroot_dst}/libx32", "-mx32"
        when 'mips64'
          gen_crt_objects api_level, arch, "platforms/common/src", platform_src_arch, "#{sysroot_dst}/lib",     "-mabi=32", "-mips32"
          gen_crt_objects api_level, arch, "platforms/common/src", platform_src_arch, "#{sysroot_dst}/libr2",   "-mabi=32", "-mips32r2"
          gen_crt_objects api_level, arch, "platforms/common/src", platform_src_arch, "#{sysroot_dst}/libr6",   "-mabi=32", "-mips32r6"
          gen_crt_objects api_level, arch, "platforms/common/src", platform_src_arch, "#{sysroot_dst}/lib64r2", "-mabi=64", "-mips64r2"
          gen_crt_objects api_level, arch, "platforms/common/src", platform_src_arch, "#{sysroot_dst}/lib64",   "-mabi=64", "-mips64r6"
        when 'mips'
          gen_crt_objects api_level, arch, "platforms/common/src", platform_src_arch, "#{sysroot_dst}/lib",   "-mabi=32", "-mips32"
          gen_crt_objects api_level, arch, "platforms/common/src", platform_src_arch, "#{sysroot_dst}/libr2", "-mabi=32", "-mips32r2"
          gen_crt_objects api_level, arch, "platforms/common/src", platform_src_arch, "#{sysroot_dst}/libr6", "-mabi=32", "-mips32r6"
        else
          gen_crt_objects api_level, arch, "platforms/common/src", platform_src_arch, "#{sysroot_dst}/#{lib_dir}"
        end

        # Generate shared libraries from symbol files
        case arch.name
        when 'x86_64'
          gen_shared_libraries arch, "#{platform_src}/arch-#{arch}/symbols", "#{sysroot_dst}/lib",    "-m32"
          gen_shared_libraries arch, "#{platform_src}/arch-#{arch}/symbols", "#{sysroot_dst}/lib64",  "-m64"
          gen_shared_libraries arch, "#{platform_src}/arch-#{arch}/symbols", "#{sysroot_dst}/libx32", "-mx32"
        when 'mips64'
          gen_shared_libraries arch, "#{platform_src}/arch-#{arch}/symbols", "#{sysroot_dst}/lib",     "-mabi=32", "-mips32"
          gen_shared_libraries arch, "#{platform_src}/arch-#{arch}/symbols", "#{sysroot_dst}/libr2",   "-mabi=32", "-mips32r2"
          gen_shared_libraries arch, "#{platform_src}/arch-#{arch}/symbols", "#{sysroot_dst}/libr6",   "-mabi=32", "-mips32r6"
          gen_shared_libraries arch, "#{platform_src}/arch-#{arch}/symbols", "#{sysroot_dst}/lib64r2", "-mabi=64", "-mips64r2"
          gen_shared_libraries arch, "#{platform_src}/arch-#{arch}/symbols", "#{sysroot_dst}/lib64",   "-mabi=64", "-mips64r6"
        when 'mips'
          gen_shared_libraries arch, "#{platform_src}/arch-#{arch}/symbols", "#{sysroot_dst}/lib",   "-mabi=32", "-mips32"
          gen_shared_libraries arch, "#{platform_src}/arch-#{arch}/symbols", "#{sysroot_dst}/libr2", "-mabi=32", "-mips32r2"
          gen_shared_libraries arch, "#{platform_src}/arch-#{arch}/symbols", "#{sysroot_dst}/libr6", "-mabi=32", "-mips32r6"
        else
          gen_shared_libraries arch, "#{platform_src}/arch-#{arch}/symbols", "#{sysroot_dst}/#{lib_dir}"
        end

        prev_sysroot_dst = sysroot_dst
      end
    end
  end

  # todo:
  # def copy_samples
  #   puts "= coping samples"
  #   FileUtils.cp_r "#{Global::NDK_DIR}/samples", install_dir
  #   copy_src_directory 'samples', 'samples'
  #   Build::API_LEVELS.each { |api_level| copy_src_directory "platforms/android-#{api_level}/samples", samples
  # end

  def patch_sysroot_header_and_libraries
    # todo: import code from patch-sysroot into crew
    puts "= patching sysroot"
    build_env.clear
    build_env['CREW_NDK_DIR'] = install_dir
    system "#{Global::NDK_DIR}/sources/crystax/bin/patch-sysroot", '--verbose', '--headers', '--libraries'
  end

  def copy_src_directory(src, dst)
    sdir = File.join(src_dir, src)
    ddir = File.join(install_dir, dst)
    if File.directory? sdir
      FileUtils.mkdir_p ddir
      FileUtils.cd(sdir) { FileUtils.cp_r Dir['*'], ddir }
    end
  end

  def generate_api_level(api_level, arch)
    file = "#{install_dir}/platforms/android-#{api_level}/arch-#{arch}/usr/include/android/api-level.h"
    lines = ["/*",
             " * Copyright (C) 2008 The Android Open Source Project",
             " * All rights reserved.",
             " *",
             " * Redistribution and use in source and binary forms, with or without",
             " * modification, are permitted provided that the following conditions",
             " * are met:",
             " *  * Redistributions of source code must retain the above copyright",
             " *    notice, this list of conditions and the following disclaimer.",
             " *  * Redistributions in binary form must reproduce the above copyright",
             " *    notice, this list of conditions and the following disclaimer in",
             " *    the documentation and/or other materials provided with the",
             " *    distribution.",
             " *",
             " * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS",
             " * \"AS IS\" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT",
             " * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS",
             " * FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE",
             " * COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,",
             " * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,",
             " * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS",
             " * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED",
             " * AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,",
             " * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT",
             " * OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF",
             " * SUCH DAMAGE.",
             " */",
             "#ifndef ANDROID_API_LEVEL_H",
             "#define ANDROID_API_LEVEL_H",
             "",
             "#define __ANDROID_API__ #{api_level}",
             "",
             "#endif /* ANDROID_API_LEVEL_H */"
            ]
    FileUtils.mkdir_p File.dirname(file)
    File.open(file, 'w') { |f| f.puts lines.join("\n") }
  end

  def gen_crt_objects(api_level, arch, common_src, src, dst, *flags)
    common_src_dir = "#{src_dir}/#{common_src}"
    srcdir = "#{src_dir}/#{src}"
    dstdir = "#{install_dir}/#{dst}"

    raise "not directory: #{srcdir}" unless File.directory? srcdir

    # Let's locate the toolchain we're going to use
    cc = Build::default_c_compiler_for_arch(arch)

    crtbrand_s = "#{dstdir}/crtbrand.s"
    #log "Generating platform $API crtbrand assembly code: $CRTBRAND_S"
    # todo: what's pwd?
    FileUtils.cd(common_src_dir) do
      FileUtils.mkdir_p dstdir
      args = flags+ ["-DPLATFORM_SDK_VERSION=#{api_level}", '-fpic', '-S', '-o', '-', 'crtbrand.c']
      out = Utils.run_command(cc, *args).each_line.map { |l| l =~ /\.note\.ABI-tag/ ? l.sub(/progbits/, 'note') : l }
      File.open(crtbrand_s, 'w') { |f| out.each { |l| f.puts l } }
    end

    FileUtils.cd(srcdir) do
      Dir['crt*.[cS]'].sort.each do |src_file|
        dst_file = src_file.sub(/\.[cS]/, '.o')
        case dst_file
        when 'crtend.o'
          # Special case: crtend.S must be compiled as crtend_android.o
          # This is for long historical reasons, i.e. to avoid name conflicts
          # in the past with other crtend.o files. This is hard-coded in the
          # Android toolchain configuration, so switch the name here.
          dst_file = 'crtend_android.o'
        when 'crtbegin_dynamic.o', 'crtbegin_static.o'
          # Add .note.ABI-tag section
          src_file += ' ' + crtbrand_s
        when 'crtbegin.o'
          # If we have a single source for both crtbegin_static.o and
          # crtbegin_dynamic.o we generate one and make a copy later.
          dst_file = 'crtbegin_dynamic.o'
          # Add .note.ABI-tag section
          src_file += ' ' + crtbrand_s
        end

        #log "Generating $ARCH C runtime object: $DST_FILE"
        args = flags + ["-I#{src_dir}/../../bionic/libc/include",
                        "-I#{src_dir}/../../bionic/libc/arch-common/bionic",
                        "-I#{src_dir}/../../bionic/libc/arch-$ARCH/include",
                        "-DPLATFORM_SDK_VERSION=#{api_level}",
                        "-O2",
                        "-fpic",
                        "-Wl,-r -nostdlib"
                       ]
        system cc, *args, '-o',"#{dstdir}/#{dst_file}", src_file

        FileUtils.cp "#{dstdir}/crtbegin_dynamic.o", "#{dstdir}/crtbegin_static.o" unless File.size? "#{dstdir}/crtbegin_static.o"
      end
      FileUtils.rm_f crtbrand_s
    end
  end

  def gen_shared_libraries(arch, symdir, dstdir, *flags)
    sym_dir = "#{src_dir}/#{symdir}"
    dst_dir = "#{install_dir}/#{dstdir}"

    # In certain cases, the symbols directory doesn't exist,
    # e.g. on x86 for PLATFORM < 9
    return unless File.directory? sym_dir

    # Let's list the libraries we're going to generate
    Dir["#{sym_dir}/*.so.functions.txt"].sort.uniq.map {|f| File.basename(f, '.functions.txt') }.each do |lib|
      ff = "#{sym_dir}/#{lib}.functions.txt"
      funs = File.exist?(ff) ? File.read(ff).split("\n") : []

      ff = "#{sym_dir}/#{lib}.variables.txt"
      vars = File.exist?(ff) ? File.read(ff).split("\n") : []

      funs = remove_unwanted_function_symbols(arch, ['libgcc.a', lib], funs)
      vars = remove_unwanted_variable_symbols(arch, ['libgcc.a', lib], vars)

      # todo: logging?
      #log "Generating $ARCH shared library for $LIB ($numfuncs functions + $numvars variables)"
      gen_shared_lib lib, funs, vars, "#{dst_dir}/#{lib}", Build::default_c_compiler_for_arch(arch), flags
    end
  end

  def remove_unwanted_function_symbols(arch, libs, symbols)
    # todo: tools here or instruments?
    unwanted_symbols_files = libs.map { |l| "#{Global::NDK_DIR}/build/instruments/unwanted-symbols/#{arch}/#{l}.functions.txt" }
    remove_unwanted_symbols unwanted_symbols_files, symbols
  end

  def remove_unwanted_variable_symbols(arch, libs, symbols)
    # todo: tools here or instruments?
    unwanted_symbols_files = libs.map { |l| "#{Global::NDK_DIR}/build/instruments/unwanted-symbols/#{arch}/#{l}.variables.txt" }
    remove_unwanted_symbols unwanted_symbols_files, symbols
  end

  def remove_unwanted_symbols(unwanted_symbols_files, symbols)
    unwanted_symbols_files.each do |file|
      if File.exist? file
        unwanted = File.read(file).split("\n")
        symbols = symbols - unwanted
      end
    end
    symbols
  end

  def gen_shared_lib(lib, funs, vars, libfile, cc, *flags)
    tmpdir = File.join(build_base_dir, 'tmp')
    FileUtils.mkdir_p tmpdir
    FileUtils.cd(tmpdir) do
      file_c = 'tmp-platform.c'   #"#{lib}.c"
      File.open(file_c, 'w') do |f|
        funs.each { |fun| f.puts "void #{fun}(void) {}" }
        vars.each { |var| f.puts "int #{var} = 0;" }
      end

      # Build it with our cross-compiler. It will complain about conflicting
      # types for built-in functions, so just shut it up.
      file_o = 'tmp-platform.o'   #"#{lib}.o"
      args = flags + ['-Wl,-shared,-Bsymbolic', "-Wl,-soname,#{lib}", '-nostdlib', '-Wl,--exclude-libs,libgcc.a']
      system cc, *args, '-o', file_o, file_c

      # Copy to our destination now
      lib_dir = File.dirname(libfile)
      FileUtils.mkdir_p lib_dir
      FileUtils.cp file_o, libfile
      FileUtils.cp libfile, "#{lib_dir}/libbionic.so" if lib == 'libc.so'
    end
    FileUtils.rm_rf tmpdir
  end
end
