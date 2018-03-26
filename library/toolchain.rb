require_relative 'global.rb'
require_relative 'arch.rb'


module Toolchain

  class GCC
    attr_reader :type, :version, :name

    def initialize(version)
      @type = 'gcc'
      @version = version
      @name = "#{type}-#{version}"
    end

    def c_compiler(arch, _abi)
      "#{tc_prefix(arch)}/bin/#{arch.host}-#{c_compiler_name}"
    end

    def cxx_compiler(arch, _abi)
      "#{tc_prefix(arch)}/bin/#{arch.host}-#{cxx_compiler_name}"
    end

    def tools(arch)
      tp = tc_prefix(arch)
      ar = "#{tp}/bin/#{arch.host}-ar"
      ranlib = "#{tp}/bin/#{arch.host}-ranlib"
      readelf = "#{tp}/bin/#{arch.host}-readelf"
      [ar, ranlib, readelf]
    end

    def tool(arch, name)
      "#{tc_prefix(arch)}/bin/#{arch.host}-#{name}"
    end

    def c_compiler_name
      'gcc'
    end

    def cxx_compiler_name
      'g++'
    end

    def stl_lib_name
      'gnustl'
    end

    def stl_name
      "gnu-#{version}"
    end

    def search_path_for_stl_includes(abi)
      "-I#{Global::NDK_DIR}/sources/cxx-stl/gnu-libstdc++/#{version}/include " \
      "-I#{Global::NDK_DIR}/sources/cxx-stl/gnu-libstdc++/#{version}/libs/#{abi}/include"
    end

    def search_path_for_stl_libs(abi)
      "-L#{Global::NDK_DIR}/sources/cxx-stl/gnu-libstdc++/#{version}/libs/#{abi}"
    end

    def cflags(abi)
      f = '-fPIC -fPIE'
      case abi
      when 'armeabi-v7a'
        f += ' -mthumb -march=armv7-a -mfpu=vfpv3-d16 -mfloat-abi=softfp'
      when 'armeabi-v7a-hard'
        f += ' -mthumb -march=armv7-a -mfpu=vfpv3-d16 -mhard-float'
      end
      f
    end

    def ldflags(abi)
      f = "-L#{Global::NDK_DIR}/sources/crystax/libs/#{abi} -pie"
      case abi
      when 'armeabi-v7a'
        f += ' -Wl,--fix-cortex-a8'
      when 'armeabi-v7a-hard'
        f += ' -Wl,--fix-cortex-a8 -Wl,--no-warn-mismatch'
      end
      f
    end

    def find_so_needs(lib, arch)
      objdump = "#{tc_prefix(arch)}/bin/#{arch.host}-objdump"
      Utils.run_command(objdump, '-p', lib).split("\n").select { |l| l =~ /NEEDED/ }.map { |l| l.split(' ')[1].split('.')[0] }
    end

    # private

    def tc_prefix(arch)
      "#{Global::NDK_DIR}/toolchains/#{arch.toolchain}-#{version}/prebuilt/#{Global::PLATFORM_NAME}"
    end
  end


  class LLVM
    attr_reader :type, :version, :name, :gcc_toolchain

    def initialize(version, gcc_toolchain)
      @type = 'llvm'
      @version = version
      @gcc_toolchain = gcc_toolchain
      @name = "#{type}-#{version}"
    end

    def c_compiler(arch, abi)
      "#{tc_prefix(abi)}/bin/#{c_compiler_name} -target #{target(abi)} -gcc-toolchain #{gcc_toolchain.tc_prefix(arch)}"
    end

    def cxx_compiler(arch, abi)
      "#{tc_prefix(abi)}/bin/#{cxx_compiler_name} -target #{target(abi)} -gcc-toolchain #{gcc_toolchain.tc_prefix(arch)}"
    end

    def tool(arch, name)
      if name == 'cpp'
        "#{c_compiler} -E"
      else
        gcc_toolchain.tool(arch, name)
      end
    end

    def c_compiler_name
      'clang'
    end

    def cxx_compiler_name
      'clang++'
    end

    def stl_lib_name
      'c++'
    end

    def stl_name
      "llvm-#{version}"
    end

    def search_path_for_stl_includes(abi)
      "-I#{Global::NDK_DIR}/sources/cxx-stl/llvm-libc++/#{version}/libcxx/include " \
      "-I#{Global::NDK_DIR}/sources/cxx-stl/llvm-libc++abi/libcxxabi/include"
    end

    def search_path_for_stl_libs(abi)
      "-L#{Global::NDK_DIR}/sources/cxx-stl/llvm-libc++/#{version}/libs/#{abi}"
    end

    def cflags(abi)
      f = "#{gcc_toolchain.cflags(abi)} -fno-integrated-as"
      case abi
      when 'x86'
        f += ' -m32'
      when 'x86_64'
        f += ' -m64'
      when 'mips'
        f += ' -mabi=32 -mips32'
      when 'mips64'
        f += ' -mabi=64 -mips64r6'
      end
      f
    end

    def ldflags(abi)
      gcc_toolchain.ldflags(abi)
    end

    def find_so_needs(lib, arch)
      gcc_toolchain.find_so_needs lib, arch
    end

    def tc_prefix(_arch)
      "#{Global::NDK_DIR}/toolchains/llvm-#{version}/prebuilt/#{Global::PLATFORM_NAME}"
    end

    def target(abi)
      case abi
      when /^armeabi-v7a/
        'armv7-none-linux-androideabi'
      when 'arm64-v8a'
        'aarch64-none-linux-android'
      when 'x86'
        'i686-none-linux-android'
      when 'x86_64'
        'x86_64-none-linux-android'
      when 'mips'
            'mipsel-none-linux-android'
      when 'mips64'
        'mips64el-none-linux-android'
      else
        raise UnknownAbi.new(abi)
      end
    end
  end

  GCC_4_9 = GCC.new('4.9')
  GCC_5   = GCC.new('5')
  GCC_6   = GCC.new('6')

  DEFAULT_GCC = GCC_5
  SUPPORTED_GCC = [GCC_4_9, GCC_5, GCC_6]

  LLVM_3_6 = LLVM.new('3.6', DEFAULT_GCC)
  LLVM_3_7 = LLVM.new('3.7', DEFAULT_GCC)
  LLVM_3_8 = LLVM.new('3.8', DEFAULT_GCC)

  DEFAULT_LLVM = LLVM_3_8
  SUPPORTED_LLVM = [LLVM_3_6, LLVM_3_7, LLVM_3_8]


  class Standalone
    attr_reader :base_dir, :sysroot_dir

    def initialize(arch, base_dir, gcc_toolchain, llvm_toolchain, with_packages, formula)
      @arch     = arch
      @base_dir = base_dir
      @gcc_toolchain = gcc_toolchain
      @llvm_toolchain = llvm_toolchain
      @bin_dir     = "#{base_dir}/bin"
      @sysroot_dir = "#{base_dir}/sysroot"

      args = ["#{Global::BASE_DIR}/crew",
              "-b",
              "make-standalone-toolchain",
              "--arch=#{arch.name}",
              "--install-dir=#{base_dir}",
              "--clean-install-dir",
              "--gcc-version=#{gcc_toolchain.version}"
             ]
      args << "--with-packages=#{with_packages.join(',')}" unless with_packages.empty?

      formula.system *args
    end

    def gcc
      tool '', 'gcc'
    end

    def gxx
      tool '', 'g++'
    end

    def tool(_arch, name)
      "#{tool_prefix}-#{name}"
    end

    def gcc_cflags(abi)
      @gcc_toolchain.cflags abi
    end

    def gcc_ldflags(abi)
      @gcc_toolchain.ldflags(abi).gsub("-L#{Global::NDK_DIR}/sources/crystax/libs/#{abi}", '')
    end

    def tool_prefix
      "#{@bin_dir}/#{@arch.host}"
    end

    def remove_dynamic_libcrystax
      FileUtils.rm "#{@base_dir}/#{@arch.host}/lib/libcrystax.so"
    end
  end
end
