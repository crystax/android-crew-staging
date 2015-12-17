require 'date'
require_relative 'exceptions.rb'
require_relative 'global.rb'


module Build

  GCC_VERSION = '4.9'
  MIN_32_API_LEVEL = 9
  MIN_64_API_LEVEL = 21

  USER = ENV['USER']

  BASE_DIR  = "/tmp/ndk-#{USER}/target"
  CACHE_DIR = "/var/tmp/ndk-cache-#{USER}"

  class Arch
    attr_reader :name, :min_api_level, :host, :toolchain, :abis

    def initialize(name, api, host, toolchain, abis)
      @name = name
      @min_api_level = api
      @host = host
      @toolchain = toolchain
      @abis = abis
    end
  end

  ARCH_LIST = [ Arch.new('arm',    MIN_32_API_LEVEL, 'arm-linux-androideabi',  'arm-linux-androideabi',  ['armeabi', 'armeabi-v7a', 'armeabi-v7a-hard']),
                Arch.new('x86',    MIN_32_API_LEVEL, 'i686-linux-android',     'x86',                    ['x86']),
                Arch.new('mips',   MIN_32_API_LEVEL, 'mipsel-linux-android',   'mipsel-linux-android',   ['mips']),
                Arch.new('arm64',  MIN_64_API_LEVEL, 'aarch64-linux-android',  'aarch64-linux-android',  ['arm64-v8a']),
                Arch.new('x86_64', MIN_64_API_LEVEL, 'x86_64-linux-android',   'x86_64',                 ['x86_64']),
                Arch.new('mips64', MIN_64_API_LEVEL, 'mips64el-linux-android', 'mips64el-linux-android', ['mips64'])
              ]


  def self.cflags(abi)
    case abi
    when 'armeabi'
      "-mthumb -march=armv5te -mtune=xscale -msoft-float"
    when 'armeabi-v7a'
      "-mthumb -march=armv7-a -mfpu=vfpv3-d16 -mfloat-abi=softfp"
    when 'armeabi-v7a-hard'
      "-mthumb -march=armv7-a -mfpu=vfpv3-d16 -mhard-float"
    else
      ""
    end
  end

  def self.ldflags(abi)
    f = "-L#{Global::NDK_DIR}/sources/crystax/libs/#{abi}"
    case abi
    when 'armeabi-v7a-hard'
      f += ' -Wl,--no-warn-mismatch'
    end
    f
  end

  def self.tools(abi)
    arch = arch_for_abi(abi)
    tc_prefix = "#{Global::NDK_DIR}/toolchains/#{arch.toolchain}-#{GCC_VERSION}/prebuilt/#{File.basename(Global::TOOLS_DIR)}"

    gcc    = "#{tc_prefix}/bin/#{arch.host}-gcc --sysroot=#{Global::NDK_DIR}/platforms/android-#{arch.min_api_level}/arch-#{arch.name}"
    ar     = "#{tc_prefix}/bin/#{arch.host}-ar"
    ranlib = "#{tc_prefix}/bin/#{arch.host}-ranlib"

    [gcc, ar, ranlib]
  end

  # this wrapper removes versions from sonames
  def self.gen_fix_soname_wrapper(gcc_wrapper, gcc)
    File.open(gcc_wrapper, "w") do |f|
      f.puts '#!/bin/bash'
      f.puts 'ARGS='
      f.puts 'NEXT_ARG_IS_SONAME=no'
      f.puts 'for p in "$@"; do'
      f.puts '    case $p in'
      f.puts '        -Wl,-soname)'
      f.puts '            NEXT_ARG_IS_SONAME=yes'
      f.puts '            ;;'
      f.puts '        *)'
      f.puts '            if [ "$NEXT_ARG_IS_SONAME" = "yes" ]; then'
      f.puts '                p=$(echo $p | sed "s,\.so.*$,.so,")'
      f.puts '                NEXT_ARG_IS_SONAME=no'
      f.puts '            fi'
      f.puts '    esac'
      f.puts '    ARGS="$ARGS $p"'
      f.puts 'done'
      f.puts "exec #{gcc} $ARGS"
    end
    FileUtils.chmod "a+x", gcc_wrapper
  end

  def self.gen_android_mk(filename, libs)
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
        #f.puts "LOCAL_EXPORT_LDLIBS := #{m.params[:export_ldlibs]}" if m.params[:export_ldlibs]
        f.puts "include $(PREBUILT_STATIC_LIBRARY)"
        f.puts ""
        f.puts "include $(CLEAR_VARS)"
        f.puts "LOCAL_MODULE := #{lib}_shared"
        f.puts "LOCAL_SRC_FILES := libs/$(TARGET_ARCH_ABI)/#{lib}.so"
        f.puts "LOCAL_EXPORT_C_INCLUDES := $(LOCAL_PATH)/include"
        #f.puts "LOCAL_EXPORT_LDLIBS := #{m.params[:export_ldlibs]}" if m.params[:export_ldlibs]
        f.puts "include $(PREBUILT_SHARED_LIBRARY)"
        f.puts ""
      end
    end
  end

  def self.arch_for_abi(abi)
    ARCH_LIST.select { |arch| arch.abis.include? abi } [0]
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
