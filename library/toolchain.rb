require_relative 'global.rb'
require_relative 'arch.rb'


module Toolchain

  class GCC
    attr_reader :type, :version, :name

    def initialize(type, version)
      @type = type
      @version = version
      @name = "#{type}-#{version}"
    end

    def c_compiler(arch)
      "#{tc_prefix(arch)}/bin/#{arch.host}-gcc"
    end

    def cxx_compiler(arch)
      "#{tc_prefix(arch)}/bin/#{arch.host}-g++"
    end

    def tools(arch)
      tp = tc_prefix(arch)
      ar = "#{tp}/bin/#{arch.host}-ar"
      ranlib = "#{tp}/bin/#{arch.host}-ranlib"
      [ar, ranlib]
    end

    def tool_path(name, arch)
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

    private

    def tc_prefix(arch)
      "#{Global::NDK_DIR}/toolchains/#{arch.toolchain}-#{version}/prebuilt/#{File.basename(Global::TOOLS_DIR)}"
    end
  end


  # todo:
  class LLVM
    attr_reader :type, :version, :name

    def initialize(name, version, gcc_toolchain)
      @name = name
      @version = version
      @gcc_toolchain = gcc_toolchain
      @name = name
    end

    def c_compiler
    end

    def cxx_compiler
    end

    def tools
    end

    def search_path_for_stl_includes(abi)
    end

    def search_path_for_stl_libs(abi)
    end
  end

  GCC_4_9 = GCC.new('gcc', '4.9')
  GCC_5   = GCC.new('gcc', '5')
end
