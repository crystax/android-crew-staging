require 'fileutils'
require_relative '../exceptions.rb'
require_relative '../formulary.rb'
require_relative 'make_standalone_toolchain_options.rb'

module Crew

  PYTHON_XX = 'python2.7'

  def self.make_standalone_toolchain(args)

    options, args = MakeStandaloneToolchainOptions.parse_args(args)
    raise CommandRequresNoArguments if args.count > 0

    puts "Create standalone toolchain in #{options.install_dir}"
    puts "  GCC version:         #{options.gcc.version}"
    puts "  LLVM version:        #{options.llvm.version}"
    puts "  STL type:            #{options.stl}"
    puts "  platform:            #{options.platform.name}"
    puts "  target architecture: #{options.arch.name}"
    puts "  API level:           #{options.api_level}"
    puts "  with packages:       #{options.with_packages.join(',')}"
    puts ''

    install_dir         = options.install_dir                   # TMPDIR
    install_include_dir = File.join(install_dir, 'include')
    install_lib_dir     = File.join(install_dir, 'lib')
    install_bin_dir     = File.join(install_dir, 'bin')
    FileUtils.mkdir_p [install_include_dir, install_bin_dir, install_lib_dir]

    host_exe  = options.platform.target_exe_ext
    tools_dir = Global.tools_dir(options.platform.name)

    FileUtils.cd(Global::NDK_DIR) do
      gcc_toolchain_dir = File.join('toolchains', "#{options.arch.toolchain}-#{options.gcc.version}", 'prebuilt', options.platform.name)
      puts "= copying GCC toolchain prebuilt binaries"
      FileUtils.cp_r Dir["#{gcc_toolchain_dir}/*"], install_dir

      puts "= copying host Python files from"
      FileUtils.cp_r File.join(tools_dir, 'include', PYTHON_XX), install_include_dir
      FileUtils.cp_r File.join(tools_dir, 'lib', PYTHON_XX),     install_lib_dir
      FileUtils.cp Dir["#{tools_dir}/python*"],                  install_bin_dir
      FileUtils.cp Dir["#{tools_dir}/bin/lib#{PYTHON_XX}.dll"],  install_bin_dir if options.platform.target_os == 'windows'

      # copy yasm for x86
      FileUtils.cp Dir["#{tools_dir}/bin/yasm*"], install_bin_dir if options.arch.name == 'x86'

      llvm_toolchain_dir = File.join('toolchains', "llvm-#{options.llvm.version}", 'prebuilt', options.platform.name)
      puts "= copying LLVM toolchain prebuilt binaries"
      FileUtils.cp_r Dir["#{llvm_toolchain_dir}/*"], install_dir

      # Move clang and clang++ to clang${LLVM_VERSION} and clang${LLVM_VERSION}++,
      # then create scripts linking them with predefined -target flag.  This is to
      # make clang/++ easier drop-in replacement for gcc/++ in NDK standalone mode.
      # Note that the file name of "clang" isn't important, and the trailing
      # "++" tells clang to compile in C++ mode

      # Need to remove '.' from LLVM_VERSION when constructing new clang name,
      # otherwise clang3.3++ may still compile *.c code as C, not C++, which
      # is not consistent with g++
      FileUtils.cd(install_bin_dir) do
        llvm_ver   = options.llvm.version.delete('.')
        clang      = "clang#{host_exe}"
        clang_v    = "clang#{llvm_ver}#{host_exe}"
        clang_xx   = "clang++#{host_exe}"
        clang_v_xx = "clang#{llvm_ver}++#{host_exe}"

        FileUtils.mv clang,  clang_v
        if not File.symlink? clang_xx
          FileUtils.mv clang_xx, clang_v_xx
        else
          FileUtils.rm clang_xx
          File.symlink clang_v, clang_v_xx
        end

        write_clang_scripts install_bin_dir, options
      end

      puts "= copying sysroot headers and libraries"
      # Copy the sysroot under #{install_dir}/sysroot. The toolchain was built to
      # expect the sysroot files to be placed there!
      src_sysroot_inc = "platforms/android-#{options.api_level}/arch-#{options.arch.name}/usr/include"
      src_sysroot_lib = "platforms/android-#{options.api_level}/arch-#{options.arch.name}/usr/lib"
      install_sysroot_usr_dir = File.join(install_dir, 'sysroot', 'usr')
      FileUtils.mkdir_p install_sysroot_usr_dir
      FileUtils.cp_r src_sysroot_inc, install_sysroot_usr_dir
      FileUtils.cp_r src_sysroot_lib, install_sysroot_usr_dir
      # x86_64 and mips* toolchain are built multilib.
      case options.arch.name
      when 'x86_64'
        FileUtils.cp_r "#{src_sysroot_lib}/../lib64",  install_sysroot_usr_dir
        FileUtils.cp_r "#{src_sysroot_lib}/../libx32", install_sysroot_usr_dir
      when 'mips'
        FileUtils.cp_r "#{src_sysroot_lib}/../libr2", install_sysroot_usr_dir
        FileUtils.cp_r "#{src_sysroot_lib}/../libr6", install_sysroot_usr_dir
      when 'mips64'
        FileUtils.cp_r "#{src_sysroot_lib}/../libr2",    install_sysroot_usr_dir
        FileUtils.cp_r "#{src_sysroot_lib}/../libr6",    install_sysroot_usr_dir
        FileUtils.cp_r "#{src_sysroot_lib}/../libr64",   install_sysroot_usr_dir
        FileUtils.cp_r "#{src_sysroot_lib}/../libr64r2", install_sysroot_usr_dir
      end
      # remove this libstdc++ library to avoid possible clashes with real ones
      FileUtils.rm Dir['/tmp/crew-gcc/sysroot/usr/**/libstdc++*']
      # todo: do we still need this?
      #if [ "$ARCH_INC" != "$ARCH" ]; then
      #  cp -a $NDK_DIR/$GCCUNWIND_SUBDIR/libs/$ABI/* $TMPDIR/sysroot/usr/lib
      #  if [ "$ARCH" = "${ARCH%%64*}" ]; then
      #    cp -a $NDK_DIR/$COMPILER_RT_SUBDIR/libs/$ABI/* $TMPDIR/sysroot/usr/lib
      #  fi
      #fi
      FileUtils.cp Dir["platforms/#{options.platform.name}/arch-#{options.arch.name}/usr/lib/crt*"], "#{install_sysroot_usr_dir}/lib/"

      puts "= copying required packages:"
      formulary = Formulary.new
      ['libcrystax', 'libobjc2'].each do |package_name|
        formula = formulary["target/#{package_name}"]
        puts "    #{formula.name}"
        formula.copy_to_standalone_toolchain(options.arch, install_dir)
      end


      # target_lib_dir = File.join(install_dir, arch.host)
      # make_target_lib_dirs target_lib_dir

      # copy_crystax_libs arch, install_dir, target_dir

    end
  end

  def self.write_clang_scripts(bin_dir, options)
    clang       = "clang#{options.llvm.version}"
    clangxx     = "clang#{options.llvm.version}++"

    llvm_ver = options.llvm.version.delete('.')
    llvm_target = options.llvm.target(options.arch.abis[0])
    toolchain_prefix = options.arch.host

    target_flag = "-target #{llvm_target}"
    clang_flags = "#{target_flag} --sysroot `dirname $0`/../sysroot"

    FileUtils.cd(bin_dir) do
      clang_shell_script 'clang',   clang, clang_flags
      clang_shell_script 'clang++', clangxx, clang_flags
      FileUtils.chmod 0755, ['clang', 'clang++']
      FileUtils.cp 'clang',   "{toolchain_prefix}-clang"
      FileUtils.cp 'clang++', "{toolchain_prefix}-clang++"

      if options.platform.target_os == 'window'
        clang_flags = target_flag + ' --sysroot %~dp0\\..\\sysroot'
        clang_cmd_script 'clang.cmd', "#{clang}.exe", clang_flags
        clang_cmd_script 'clang.cmd', "#{clangxx}.exe", clang_flags
        FileUtils.chmod 0755, ['clang.cmd', 'clang++.cmd']
        FileUtils.cp 'clang.cmd',   "#{toolchain_prefix}-clang.cmd"
        FileUtils.cp 'clang++.cmd', "#{toolchain_prefix}-clang++.cmd"
      end
    end
  end

  def self.clang_shell_script(file, clang, flags)
    File.open(file, 'w') do |f|
      f.puts "#!/bin/bash"
      f.puts "if [ \"$1\" != \"-cc1\" ]; then"
      f.puts "    `dirname $0\`#{clang} #{flags} \"$@\""
      f.puts "else"
      f.puts "    # target/triple already spelled out."
      f.puts "    `dirname $0`/#{clang} \"$@\""
      f.puts "fi"
    end
  end

  def self.clang_cmd_script(file, clang, flags)
    File.open(file, 'w') do |f|
      f.puts "@echo off"
      f.puts "if \"%1\" == \"-cc1\" goto :L"
      f.puts "%~dp0\\#{clang}}.exe #{flags} %*"
      f.puts "if ERRORLEVEL 1 exit /b 1"
      f.puts "goto :done"
      f.puts ":L"
      f.puts "rem target/triple already spelled out."
      f.puts "%~dp0\\#{clang}.exe %*"
      f.puts "if ERRORLEVEL 1 exit /b 1"
      f.puts ":done"
    end
  end

  def self.make_target_lib_dirs(target_dir)
    FileUtils.cd(target_dir) do
      FileUtils.mkdir_p ["lib/armv7-a/",
                         "lib/armv7-a/thumb/",
                         "lib/armv7-a/hard/",
                         "lib/armv7-a/thumb/hard/",
                         "lib",
                         "libr2",
                         "libr6",
                         "lib64/",
                         "lib64r2/",
                         "libx32/"
                        ]
    end
  end

  def self.copy_crystax_libs(arch, install_dir, target_dir)
    puts "= copying crystax headers and libraries"

    crystax_libs_dir = 'sources/crystax/libs'

    case arch.name
    when 'arm'
      FileUitls.cp Dir["#{crystax_libs_dir}/armeabi-v7a/libcrystax.*"],            "#{target_dir}/lib/armv7-a/"
      FileUitls.cp Dir["#{crystax_libs_dir}/armeabi-v7a/thumb/libcrystax.*"],      "#{target_dir}/lib/armv7-a/thumb/"
      FileUitls.cp Dir["#{crystax_libs_dir}/armeabi-v7a-hard/libcrystax.*"],       "#{target_dir}/lib/armv7-a/hard/"
      FileUitls.cp Dir["#{crystax_libs_dir}/armeabi-v7a-hard/thumb/libcrystax.*"], "#{target_dir}/lib/armv7-a/thumb/hard/"
    when 'mips'
      FileUitls.cp Dir["#{crystax_libs_dir}/mips/libcrystax.*"],    "#{target_dir}/lib"
      FileUitls.cp Dir["#{crystax_libs_dir}/mips/r2/libcrystax.*"], "#{target_dir}/libr2"
      FileUitls.cp Dir["#{crystax_libs_dir}/mips/r6/libcrystax.*"], "#{target_dir}/libr6"
    when 'mips64'
      FileUitls.cp Dir["#{crystax_libs_dir}/mips64/libcrystax.*"],         "#{target_dir}/lib64/"
      FileUitls.cp Dir["#{crystax_libs_dir}/mips64/r2/libcrystax.*"],      "#{target_dir}/lib64r2/"
      FileUitls.cp Dir["#{crystax_libs_dir}/mips64/lib32/libcrystax.*"],   "#{target_dir}/lib/"
      FileUitls.cp Dir["#{crystax_libs_dir}/mips64/lib32r2/libcrystax.*"], "#{target_dir}/libr2/"
      FileUitls.cp Dir["#{crystax_libs_dir}/mips64/lib32r6/libcrystax.*"], "#{target_dir}/libr6/"
    when 'x86_64'
      FileUitls.cp Dir["#{crystax_libs_dir}/x86_64/libcrystax.*"],     "#{target_dir}/lib64/"
      FileUitls.cp Dir["#{crystax_libs_dir}/x86_64/32/libcrystax.*"],  "#{target_dir}/lib/"
      FileUitls.cp Dir["#{crystax_libs_dir}/x86_64/x32/libcrystax.*"], "#{target_dir}/libx32/"
    else
      FileUtils.cp Dir["#{crystax_libs_dir}/#{arch.abis[0]}/libcrystax.*"], "#{target_dir}/lib/"
    end
  end
end
