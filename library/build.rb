
require 'date'
require_relative 'exceptions.rb'
require_relative 'global.rb'
require_relative 'arch.rb'
require_relative 'toolchain.rb'


module Build

  MIN_32_API_LEVEL = 9
  MIN_64_API_LEVEL = 21

  USER = ENV['USER']

  BASE_DIR  = "/tmp/ndk-#{USER}/target"
  CACHE_DIR = "/var/tmp/ndk-cache-#{USER}"

  ARCH_LIST = [ Arch.new('arm',    32, MIN_32_API_LEVEL, 'arm-linux-androideabi',  'arm-linux-androideabi',  ['armeabi', 'armeabi-v7a', 'armeabi-v7a-hard'].freeze),
                Arch.new('x86',    32, MIN_32_API_LEVEL, 'i686-linux-android',     'x86',                    ['x86']).freeze,
                Arch.new('mips',   32, MIN_32_API_LEVEL, 'mipsel-linux-android',   'mipsel-linux-android',   ['mips']).freeze,
                Arch.new('arm64',  64, MIN_64_API_LEVEL, 'aarch64-linux-android',  'aarch64-linux-android',  ['arm64-v8a']).freeze,
                Arch.new('x86_64', 64, MIN_64_API_LEVEL, 'x86_64-linux-android',   'x86_64',                 ['x86_64']).freeze,
                Arch.new('mips64', 64, MIN_64_API_LEVEL, 'mips64el-linux-android', 'mips64el-linux-android', ['mips64']).freeze
              ]

  DEFAULT_TOOLCHAIN = Toolchain::DEFAULT_GCC
  TOOLCHAIN_LIST = [ Toolchain::GCC_4_9, Toolchain::GCC_5, Toolchain::LLVM_3_6, Toolchain::LLVM_3_7 ]


  def self.def_arch_list_to_build
    ARCH_LIST.map { |a| b = a.dup ; b.abis_to_build = b.abis ; b }
  end

  def self.abis_to_arch_list(abis)
    arch_list = ARCH_LIST.map { |a| a.dup }
    abis.each do |abi|
      arch = arch_for_abi(abi, arch_list)
      arch.abis_to_build << abi
    end
    arch_list.select { |a| not a.abis_to_build.empty? }
  end

  # def self.cflags(abi)
  #   case abi
  #   when 'armeabi'
  #     '-march=armv5te -mtune=xscale -msoft-float'
  #   when 'armeabi-v7a'
  #     '-march=armv7-a -mfpu=vfpv3-d16 -mfloat-abi=softfp'
  #   when 'armeabi-v7a-hard'
  #     '-march=armv7-a -mfpu=vfpv3-d16 -mhard-float'
  #   else
  #     ""
  #   end
  # end

  # def self.ldflags(abi)
  #   f = "-L#{Global::NDK_DIR}/sources/crystax/libs/#{abi}"
  #   case abi
  #   when 'armeabi-v7a'
  #     f += ' -Wl,--fix-cortex-a8'
  #   when 'armeabi-v7a-hard'
  #     f += ' -Wl,--fix-cortex-a8 -Wl,--no-warn-mismatch'
  #   end
  #   f
  # end

  def self.arch_for_abi(abi, arch_list = ARCH_LIST)
    arch_list.select { |arch| arch.abis.include? abi } [0]
  end

  def self.sysroot(abi)
    arch = arch_for_abi(abi)
    " --sysroot=#{Global::NDK_DIR}/platforms/android-#{arch.min_api_level}/arch-#{arch.name}"
  end

  # todo: remove
  # def self.search_path_for_crystax_libs(abi)
  #   "-L#{Global::NDK_DIR}/sources/crystax/libs/#{abi}"
  # end

  def self.gen_host_compiler_wrapper(wrapper, compiler, *opts)
    # todo: we do not have platform/prebuilts in NDK distribution
    ndk_root_dir = Pathname.new(Global::NDK_DIR).realpath.dirname.dirname.to_s
    case Global::OS
    when 'darwin'
      cc = "#{ndk_root_dir}/platform/prebuilts/gcc/darwin-x86/host/x86_64-apple-darwin-4.9.3/bin/#{compiler}"
      args = "-isysroot #{ndk_root_dir}/platform/prebuilts/sysroot/darwin-x86/MacOSX10.6.sdk " \
             "-mmacosx-version-min=10.6 " \
             "-DMACOSX_DEPLOYMENT_TARGET=10.6 " \
             "-Wl,-syslibroot,#{ndk_root_dir}/platform/prebuilts/sysroot/darwin-x86/MacOSX10.6.sdk " \
             "-mmacosx-version-min=10.6"
    else
      raise "unsuppoerted OS: #{Global::OS}"
    end
    File.open(wrapper, 'w') do |f|
      f.puts '#!/bin/sh'
      f.puts ''
      f.puts "exec #{cc} #{args} #{opts.join(' ')} \"$@\""
    end
    FileUtils.chmod "a+x", wrapper
  end

  def self.gen_compiler_wrapper(wrapper, compiler, toolchain, options, cflags = '', ldflags = Hash.new(''))
    File.open(wrapper, "w") do |f|
      f.puts '#!/bin/bash'
      f.puts 'if echo "$@" | tr \' \' \'\n\' | grep -q -x -e -c; then'
      f.puts '    LINKER=no'
      f.puts 'elif echo "$@" | tr \' \' \'\n\' | grep -q -x -e -emit-pth; then'
      f.puts '    LINKER=no'
      f.puts 'else'
      f.puts '    LINKER=yes'
      f.puts 'fi'
      f.puts ''
      f.puts 'PARAMS=$@'
      f.puts 'echo "PARAMS: $PARAMS" >> /tmp/wrapper.log'
      if opts = options[:wrapper_replace]
        f.puts ''
        f.puts 'REPLACED_PARAMS='
        f.puts 'for p in $PARAMS; do'
        f.puts '    case $p in'
        opts.keys.each do |key|
          f.puts "        #{key})"
          f.puts "            p=#{opts[key]}"
          f.puts "            ;;"
        end
        f.puts '    esac'
        f.puts '    REPLACED_PARAMS="$REPLACED_PARAMS $p"'
        f.puts 'done'
        f.puts 'echo "REPLACED_PARAMS: $REPLACED_PARAMS" >> /tmp/wrapper.log'
        f.puts 'PARAMS=$REPLACED_PARAMS'
      end
      if options[:wrapper_fix_soname]
        f.puts ''
        f.puts 'echo "PARAMS: $PARAMS" >> /tmp/wrapper.log'
        f.puts 'FIXED_SONAME_PARAMS='
        f.puts 'NEXT_PARAM_IS_LIBNAME=no'
        f.puts 'for p in $PARAMS; do'
        f.puts '    if [ "x$NEXT_PARAM_IS_LIBNAME" = "xyes" ]; then'
        f.puts '        LIBNAME=`expr "x$p" : "^x.*\\(lib[^\\.]*\\.so\\)"`'
        f.puts '        p="-Wl,$LIBNAME"'
        f.puts '        NEXT_PARAM_IS_LIBNAME=no'
        f.puts '    else'
        f.puts '        case $p in'
        f.puts '            -Wl,-soname|-Wl,-h|-install_name)'
        f.puts '                p="-Wl,-soname"'
        f.puts '                NEXT_PARAM_IS_LIBNAME=yes'
        f.puts '                ;;'
        f.puts '            -Wl,-soname,lib*|-Wl,-h,lib*)'
        f.puts '                LIBNAME=`expr "x$p" : "^x.*\\(lib[^\\.]*\\.so\\)"`'
        f.puts '                p="-Wl,-soname,-l$LIBNAME"'
        f.puts '                ;;'
        f.puts '        esac'
        f.puts '    fi'
        f.puts '    FIXED_SONAME_PARAMS="$FIXED_SONAME_PARAMS $p"'
        f.puts 'done'
        f.puts 'PARAMS=$FIXED_SONAME_PARAMS'
      end
      if options[:wrapper_fix_stl]
        f.puts ''
        f.puts 'echo "PARAMS: $PARAMS" >> /tmp/wrapper.log'
        f.puts 'FIXED_STL_PARAMS='
        f.puts 'for p in $PARAMS; do'
        f.puts '  case $p in'
        f.puts '    -lstdc++)'
        f.puts "       p=\"-l#{toolchain.stl_lib_name}_shared $p\""
        f.puts '       ;;'
        f.puts '  esac'
        f.puts '  FIXED_STL_PARAMS="$FIXED_STL_PARAMS $p"'
        f.puts 'done'
        f.puts 'echo "FIXED_STL_PARAMS: $FIXED_STL_PARAMS" >> /tmp/wrapper.log'
        f.puts 'PARAMS=$FIXED_STL_PARAMS'
      end
      f.puts ''
      f.puts 'if [ "x$LINKER" = "xyes" ]; then'
      f.puts "    PARAMS=\"#{ldflags[:before]} $PARAMS #{ldflags[:after]}\""
      f.puts 'else'
      f.puts "    PARAMS=\"#{cflags} $PARAMS\""
      f.puts 'fi'
      f.puts ''
      f.puts 'echo "PARAMS: $PARAMS" >> /tmp/wrapper.log'
      f.puts "exec #{compiler} $PARAMS"
    end
    FileUtils.chmod "a+x", wrapper
  end

  # todo: remove?
  # def self.gen_tool_wrapper(dir, tool, toolchain, arch)
  #   filename = "#{dir}/#{tool}"
  #   File.open(filename, "w") do |f|
  #     f.puts "#!/bin/sh"
  #     f.puts "exec #{toolchain.tool_path(tool, arch)} \"$@\""
  #   end
  #   FileUtils.chmod "a+x", filename
  # end

  def self.gen_android_mk(filename, libs, options)
    File.open(filename, "w") do |f|
      f.puts COPYRIGHT_STR
      f.puts ""
      f.puts "LOCAL_PATH := $(call my-dir)"
      f.puts ""
      libs.each do |lib|
        f.puts "include $(CLEAR_VARS)"
        f.puts "LOCAL_MODULE := #{lib}_static"
        f.puts "LOCAL_SRC_FILES := libs/$(TARGET_ARCH_ABI)/#{lib}.a"
        f.puts "LOCAL_EXPORT_C_INCLUDES := $(LOCAL_PATH)/include"
        f.puts "LOCAL_EXPORT_LDLIBS := #{options[:export_ldlibs]}" if options[:export_ldlibs]
        f.puts "include $(PREBUILT_STATIC_LIBRARY)"
        f.puts ""
        f.puts "include $(CLEAR_VARS)"
        f.puts "LOCAL_MODULE := #{lib}_shared"
        f.puts "LOCAL_SRC_FILES := libs/$(TARGET_ARCH_ABI)/#{lib}.so"
        f.puts "LOCAL_EXPORT_C_INCLUDES := $(LOCAL_PATH)/include"
        f.puts "LOCAL_EXPORT_LDLIBS := #{options[:export_ldlibs]}" if options[:export_ldlibs]
        f.puts "include $(PREBUILT_SHARED_LIBRARY)"
        f.puts ""
      end
    end
  end

  COPYRIGHT_STR = <<-EOS
# Copyright (c) 2011-#{Date.today.strftime("%Y")} CrystaX.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification, are
# permitted provided that the following conditions are met:
#
#    1. Redistributions of source code must retain the above copyright notice, this list of
#       conditions and the following disclaimer.
#
#    2. Redistributions in binary form must reproduce the above copyright notice, this list
#       of conditions and the following disclaimer in the documentation and/or other materials
#       provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY CrystaX ''AS IS'' AND ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
# FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL CrystaX OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
# ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# The views and conclusions contained in the software and documentation are those of the
# authors and should not be interpreted as representing official policies, either expressed
# or implied, of CrystaX.
EOS

end
