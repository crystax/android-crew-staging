require 'fileutils'
require_relative '../exceptions.rb'
require_relative '../formulary.rb'
require_relative 'command.rb'
require_relative 'make_standalone_toolchain/options.rb'


module Crew

  def self.make_standalone_toolchain(args)
    MakeStandaloneToolchain.new(args).execute
  end

  class MakeStandaloneToolchain < Command

    PYTHON_XX = 'python2.7'
    PackageInfo = Options::PackageInfo

    def initialize(args)
      super args, Options
      raise CommandRequresNoArguments if self.args.count > 0
    end

    def execute
      # check that specified packages are available and set release if one was not specified
      formulary = Formulary.new
      _, dependencies = formulary.packages_formulas_with_dependencies(options.with_packages.map(&:name))
      options.with_packages.each do |package|
        formula = formulary[package.name]
        package.release = package.release ? formula.find_release(package.release) : formula.highest_installed_release
        raise "package #{package} is not installed; please, install it and repeat the command" unless formula.installed?(package.release)
        package.formula = formula
      end

      # handle dependecies
      dependencies.each do |formula|
        package = PackageInfo.new(formula.name, formula.highest_installed_release, formula)
        options.with_packages << package
      end

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

          write_clang_scripts install_bin_dir
        end

        puts "= copying sysroot headers and libraries"
        # Copy the sysroot under #{install_dir}/sysroot. The toolchain was built to
        # expect the sysroot files to be placed there!
        src_sysroot_inc = "platforms/android-#{options.api_level}/arch-#{options.arch.name}/usr/include"
        src_sysroot_lib = "platforms/android-#{options.api_level}/arch-#{options.arch.name}/usr/lib"

        install_sysroot_dir = File.join(install_dir, 'sysroot')
        install_sysroot_usr_dir = File.join(install_sysroot_dir, 'usr')
        FileUtils.mkdir_p install_sysroot_usr_dir

        FileUtils.cp_r src_sysroot_inc, install_sysroot_usr_dir
        FileUtils.cp_r src_sysroot_lib, install_sysroot_usr_dir
        # x86_64 toolchain was built with multilib support.
        case options.arch.name
        when 'x86_64'
          FileUtils.cp_r "#{src_sysroot_lib}/../lib64",  install_sysroot_usr_dir
          FileUtils.cp_r "#{src_sysroot_lib}/../libx32", install_sysroot_usr_dir
        end

        # remove this libstdc++ library to avoid possible clashes with real ones
        FileUtils.rm Dir["#{install_sysroot_usr_dir}/**/libstdc++*"]
        # copy runtime
        FileUtils.cp Dir["platforms/#{options.platform.name}/arch-#{options.arch.name}/usr/lib/crt*"], "#{install_sysroot_usr_dir}/lib/"

        # todo: do we still need this?
        #if [ "$ARCH_INC" != "$ARCH" ]; then
        #  cp -a $NDK_DIR/$GCCUNWIND_SUBDIR/libs/$ABI/* $TMPDIR/sysroot/usr/lib
        #  if [ "$ARCH" = "${ARCH%%64*}" ]; then
        #    cp -a $NDK_DIR/$COMPILER_RT_SUBDIR/libs/$ABI/* $TMPDIR/sysroot/usr/lib
        #  fi
        #fi

        puts "= copying required packages:"
        target_include_dir = File.join(install_sysroot_usr_dir, 'include')
        target_lib_dir = File.join(install_dir, options.arch.host)
        FileUtils.mkdir_p target_include_dir

        if options.stl == 'libc++'
          stl_name = 'libc++'
          stl_version = options.llvm.version
          stl_opts = { gcc_version: options.gcc.version }
        else
          stl_name = 'libstdc++'
          stl_version = options.gcc.version
          stl_opts = {}
        end

        # GNU GCC C++ headers must be copied to directory where they will be found by a compiler
        cxx_include_dir = "#{install_dir}/#{options.arch.host}/include"
        package = PackageInfo.new(stl_name, Release.new(stl_version))
        formula = formulary[package.name]
        release = package.release ? formula.find_release(package.release) : formula.highest_installed_release
        puts "    #{formula.name}:#{release}"
        formula.copy_to_standalone_toolchain(release, options.arch, cxx_include_dir, target_lib_dir, stl_opts)
        # rename C++ include dir to correspond to full GCC version
        old = options.gcc.version
        new = gcc_ver("#{install_dir}/bin/#{options.arch.host}-gcc")
        FileUtils.cd("#{cxx_include_dir}/c++") { FileUtils.mv old, new } unless old == new
        #
        if stl_name == 'libc++'
          arch_subdir = case options.arch.name
                        when 'arm'
                          'armeabi-v7a'
                        when 'arm64'
                          'arm64-v8a'
                        else
                          options.arch.name
                        end
          gccunwind_lib = "#{Global::NDK_DIR}/sources/android/gccunwind/libs/#{arch_subdir}/libgccunwind.a"
          FileUtils.cp gccunwind_lib, "#{install_sysroot_usr_dir}/lib/"
        end

        [PackageInfo.new('libcrystax'), PackageInfo.new('libobjc2')].each do |package|
          formula = formulary[package.name]
          release = package.release ? formula.find_release(package.release) : formula.highest_installed_release
          puts "    #{formula.name}:#{release}"
          formula.copy_to_standalone_toolchain(release, options.arch, target_include_dir, target_lib_dir, {})
        end

        options.with_packages.each do |package|
          puts "    #{package.name}:#{package.release}"
          package.formula.copy_to_standalone_toolchain(package.release, options.arch, target_include_dir, install_sysroot_usr_dir, {})
        end
      end
    end

    def write_clang_scripts(bin_dir)
      llvm_ver = options.llvm.version.split('.').join
      clang = "clang#{llvm_ver}"
      clangxx = "clang#{llvm_ver}++"

      llvm_ver = options.llvm.version.delete('.')
      llvm_target = options.llvm.target(options.arch.abis[0])
      toolchain_prefix = options.arch.host

      target_flag = "-target #{llvm_target}"
      clang_flags = "#{target_flag} --sysroot `dirname $0`/../sysroot"

      FileUtils.cd(bin_dir) do
        clang_shell_script 'clang',   clang, clang_flags
        clang_shell_script 'clang++', clangxx, clang_flags
        FileUtils.chmod 0755, ['clang', 'clang++']
        FileUtils.cp 'clang',   "#{toolchain_prefix}-clang"
        FileUtils.cp 'clang++', "#{toolchain_prefix}-clang++"

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

    def clang_shell_script(file, clang, flags)
      File.open(file, 'w') do |f|
        f.puts "#!/bin/bash"
        f.puts "if [ \"$1\" != \"-cc1\" ]; then"
        f.puts "    `dirname $0\`/#{clang} #{flags} \"$@\""
        f.puts "else"
        f.puts "    # target/triple already spelled out."
        f.puts "    `dirname $0`/#{clang} \"$@\""
        f.puts "fi"
      end
    end

    def clang_cmd_script(file, clang, flags)
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

    def gcc_ver(gcc_prog)
      cmd = "#{gcc_prog} -dumpversion"
      v = `#{cmd}`.strip
      raise "failed to run #{cmd}" unless $? == 0
      v
    end
  end
end
