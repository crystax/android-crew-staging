require 'date'
require_relative 'exceptions.rb'
require_relative 'global.rb'


module Build

  GCC_VERSION = '4.9'
  MIN_32_API_LEVEL = 9
  MIN_64_API_LEVEL = 21

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

  class AndroidMkModule
    attr_reader :name

    def initialize(name)
      @name = name
    end
  end

  ARCH_LIST = [ Arch.new('arm',    MIN_32_API_LEVEL, 'arm-linux-androideabi',  'arm-linux-androideabi',  ['armeabi', 'armeabi-v7a', 'armeabi-v7a-hard']),
                Arch.new('x86',    MIN_32_API_LEVEL, 'i686-linux-android',     'x86',                    ['x86']),
                Arch.new('mips',   MIN_32_API_LEVEL, 'mipsel-linux-android',   'mipsel-linux-android',   ['mips']),
                Arch.new('arm64',  MIN_64_API_LEVEL, 'aarch64-linux-android',  'aarch64-linux-android',  ['arm64-v8a']),
                Arch.new('x86_64', MIN_64_API_LEVEL, 'x86_64-linux-android',   'x86_64',                 ['x86_64']),
                Arch.new('mips64', MIN_64_API_LEVEL, 'mips64el-linux-android', 'mips64el-linux-android', ['mips64'])
              ]

  USER = ENV['USER']

  BASE_DIR  = "/tmp/ndk-#{USER}/target"
  CACHE_DIR = "/var/tmp/ndk-cache-#{USER}"

  class Builder
    attr_reader :pkg_name, :src_dir, :configure_args, :mk_modules

    def initialize(name, src_dir, conf_args, mk_modules)
      @pkg_name = name
      @src_dir = src_dir
      @configure_args = conf_args
      @mk_modules = mk_modules
      # default lib names
      @libs = [ "#{name}.a", "#{name}.so" ]
    end

    def prepare_package(arch_list)
      # build library for all archs
      arch_list.each do |arch|
        print "= building for architecture: #{arch.name}; abis: [ "
        arch.abis.each do |abi|
          print "#{abi} "
          build_for_abi(arch, abi)
        end
        puts "]"
      end
      gen_android_mk
    end

    private

    def build_for_abi(arch, abi)
      # preprare directories
      base_dir = "#{BASE_DIR}/#{pkg_name}/#{abi}"
      FileUtils.rm_rf base_dir
      build_dir = "#{base_dir}/build"
      install_dir = "#{base_dir}/install"
      FileUtils.mkdir_p install_dir
      FileUtils.cp_r @src_dir, base_dir
      FileUtils.cd(base_dir) { FileUtils.mv File.basename(@src_dir), File.basename(build_dir) }
      logfile = "#{base_dir}/build.log"
      # build
      FileUtils.cd(build_dir) do
        env = env_for_abi(arch, abi)
        run env, logfile, "./configure --prefix=#{install_dir} --host=#{arch.host} #{configure_args.join(' ')}"
        # todo: do not hardcode jobs number
        run env, logfile, "make --jobs=16"
        run env, logfile, "make install"
      end
      # copy headers and abi specific libs to the package dir
      package_libs_and_headers abi, install_dir
    end

    def env_for_abi(arch, abi)
      cflags  = "#{cflags(abi)} --sysroot=#{Global::NDK_DIR}/platforms/android-#{arch.min_api_level}/arch-#{arch.name}"
      ldflags = "#{ldflags(abi)} -L#{Global::NDK_DIR}/sources/crystax/libs/#{abi}"

      tc_prefix = "#{Global::NDK_DIR}/toolchains/#{arch.toolchain}-#{GCC_VERSION}/prebuilt/#{File.basename(Global::TOOLS_DIR)}"
      gcc = "#{tc_prefix}/bin/#{arch.host}-gcc"
      gcc_wrapper = "./cc"
      gen_fix_soname_wrapper(gcc_wrapper, gcc)

      env = {'CC'      => gcc_wrapper,
             'CPP'     => "#{gcc_wrapper} #{cflags} -E",
             'AR'      => "#{tc_prefix}/bin/#{arch.host}-ar",
             'RANLIB'  => "#{tc_prefix}/bin/#{arch.host}-ranlib",
             'CFLAGS'  => cflags,
             'LDFLAGS' => ldflags
            }
    end

    def package_libs_and_headers(abi, install_dir)
      pkg_dir = package_dir
      # copy headers if they were not copied yet
      inc_dir = "#{pkg_dir}/include"
      if !Dir.exists? inc_dir
        FileUtils.mkdir_p pkg_dir
        FileUtils.cp_r "#{install_dir}/include", pkg_dir
      end
      # copy libs
      libs_dir = "#{pkg_dir}/libs/#{abi}"
      FileUtils.mkdir_p libs_dir
      @libs.each { |lib| FileUtils.cp "#{install_dir}/lib/#{lib}", libs_dir }
    end

    def package_dir
      "#{BASE_DIR}/#{@pkg_name}/package"
    end

    def cflags(abi)
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

    def ldflags(abi)
      case abi
      when 'armeabi-v7a-hard'
        '-Wl,--no-warn-mismatch'
      else
        ''
      end
    end

    def run(env, logfile, cmd)
      File.open(logfile, "a") do |log|
        log.puts "== env: #{env}"
        log.puts "== cmd started: #{cmd}"

        rc = 0
        Open3.popen2e(env, cmd) do |_, out, wt|
          ot = Thread.start { out.read.split("\n").each { |l| log.puts l } }
          ot.join
          rc = wt && wt.value.exitstatus
        end
        log.puts "== cmd finished: exit code: #{rc} cmd: #{cmd}"
        raise "run failed with code: #{rc}; see #{logfile} for details" unless rc == 0
      end
    end

    # this wrapper removes versions from sonames
    def gen_fix_soname_wrapper(gcc_wrapper, gcc)
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

    def gen_android_mk
      filename = "#{package_dir}/Android.mk"
      File.open(filename, "w") do |f|
        f.puts COPYRIGHT_STR
        f.puts ""
        f.puts "LOCAL_PATH := $(call my-dir)"
        f.puts ""
        mk_modules.each do |m|
          f.puts "include $(CLEAR_VARS)"
          f.puts "LOCAL_MODULE := #{m.name}_static"
          f.puts "LOCAL_SRC_FILES := libs/$(TARGET_ARCH_ABI)/#{m.name}.a"
          f.puts "LOCAL_EXPORT_C_INCLUDES := $(LOCAL_PATH)/include"
          f.puts "include $(PREBUILT_STATIC_LIBRARY)"
          f.puts ""
          f.puts "include $(CLEAR_VARS)"
          f.puts "LOCAL_MODULE := #{m.name}_shared"
          f.puts "LOCAL_SRC_FILES := libs/$(TARGET_ARCH_ABI)/#{m.name}.so"
          f.puts "LOCAL_EXPORT_C_INCLUDES := $(LOCAL_PATH)/include"
          f.puts "include $(PREBUILT_SHARED_LIBRARY)"
        end
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
