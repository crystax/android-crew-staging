
require 'date'
require_relative 'exceptions.rb'
require_relative 'global.rb'
require_relative 'arch.rb'
require_relative 'toolchain.rb'


module Build

  MIN_32_API_LEVEL = 9
  MIN_64_API_LEVEL = 21

  USER = ENV['USER']

  # todo: honor CRYSTAX_NDK_BASE_TMP_DIR environment dir
  BASE_TARGET_DIR  = "/tmp/ndk-#{USER}/target"
  BASE_HOST_DIR    = "/tmp/ndk-#{USER}/host"
  CACHE_DIR        = "/var/tmp/ndk-cache-#{USER}"

  # todo:
  VENDOR_TESTS_DIR  = Pathname.new("#{Global::NDK_DIR}/../../vendor/tests").cleanpath.to_s
  TOOLCHAIN_SRC_DIR = Pathname.new("#{Global::NDK_DIR}/../../toolchain").cleanpath.to_s

  ARCH_LIST = [ Arch.new('arm',    32, MIN_32_API_LEVEL, 'arm-linux-androideabi',  'arm-linux-androideabi',  ['armeabi-v7a', 'armeabi-v7a-hard'].freeze),
                Arch.new('x86',    32, MIN_32_API_LEVEL, 'i686-linux-android',     'x86',                    ['x86']).freeze,
                Arch.new('mips',   32, MIN_32_API_LEVEL, 'mipsel-linux-android',   'mipsel-linux-android',   ['mips']).freeze,
                Arch.new('arm64',  64, MIN_64_API_LEVEL, 'aarch64-linux-android',  'aarch64-linux-android',  ['arm64-v8a']).freeze,
                Arch.new('x86_64', 64, MIN_64_API_LEVEL, 'x86_64-linux-android',   'x86_64',                 ['x86_64']).freeze,
                Arch.new('mips64', 64, MIN_64_API_LEVEL, 'mips64el-linux-android', 'mips64el-linux-android', ['mips64']).freeze
              ]

  ABI_LIST = ARCH_LIST.map { |a| a.abis }.flatten

  DEFAULT_TOOLCHAIN = Toolchain::DEFAULT_GCC
  TOOLCHAIN_LIST = [ Toolchain::GCC_4_9, Toolchain::GCC_5, Toolchain::LLVM_3_6, Toolchain::LLVM_3_7 ]


  def self.abis_to_arch_list(abis)
    arch_list = ARCH_LIST.map { |a| a.dup }
    abis.each do |abi|
      arch = arch_for_abi(abi, arch_list)
      arch.abis_to_build << abi
    end
    arch_list.select { |a| not a.abis_to_build.empty? }
  end

  def self.arch_for_abi(abi, arch_list = ARCH_LIST)
    arch_list.select { |arch| arch.abis.include? abi } [0]
  end

  def self.sysroot(abi)
    arch = arch_for_abi(abi)
    " --sysroot=#{Global::NDK_DIR}/platforms/android-#{arch.min_api_level}/arch-#{arch.name}"
  end

  def self.gen_host_compiler_wrapper(wrapper, compiler, *opts)
    # todo: we do not have platform/prebuilts in NDK distribution
    ndk_root_dir = Pathname.new(Global::NDK_DIR).realpath.dirname.dirname.to_s
    case Global::OS
    when 'darwin'
      sysroot_dir = "#{ndk_root_dir}/platform/prebuilts/sysroot/darwin-x86/MacOSX10.6.sdk"
      cc = "#{ndk_root_dir}/platform/prebuilts/gcc/darwin-x86/host/x86_64-apple-darwin-4.9.3/bin/#{compiler}"
      args = "-isysroot #{sysroot_dir} -mmacosx-version-min=10.6 -DMACOSX_DEPLOYMENT_TARGET=10.6 -Wl,-syslibroot,#{sysroot_dir} "
    when 'linux'
      sysroot_dir = "#{ndk_root_dir}/platform/prebuilts/gcc/linux-x86/host/x86_64-linux-glibc2.11-4.8/sysroot"
      cc = "#{ndk_root_dir}/platform/prebuilts/gcc/linux-x86/host/x86_64-linux-glibc2.11-4.8/bin/x86_64-linux-#{compiler}"
      args = "-isysroot #{sysroot_dir} -Wl,-syslibroot,#{sysroot_dir}"
    else
      raise "unsupported OS: #{Global::OS}"
    end
    File.open(wrapper, 'w') do |f|
      f.puts '#!/bin/sh'
      f.puts ''
      f.puts "exec #{cc} #{args} #{opts.join(' ')} \"$@\""
    end
    FileUtils.chmod "a+x", wrapper
  end

  def self.gen_compiler_wrapper(wrapper, compiler, toolchain, options, cflags = '', ldflags = nil)
    ruby = File.join(RbConfig::CONFIG['bindir'], RbConfig::CONFIG['ruby_install_name'])
    helper = File.join(File.dirname(__FILE__), 'compiler_wrapper_helper.rb')
    # todo: check ldflags value?
    ldflags = 'Hash.new("")' unless ldflags
    File.open(wrapper, "w") do |f|
      f.puts "#!#{ruby}"
      f.puts
      f.puts "require '#{helper}'"
      f.puts
      f.puts "compiler = '#{compiler}'"
      f.puts "stl_lib_name = '#{toolchain.stl_lib_name}'"
      f.puts "options = #{options}"
      f.puts "cflags = '#{cflags}'"
      f.puts "ldflags = #{ldflags}"
      f.puts
      f.puts "compiler, args = process_compiler_args(compiler, options, stl_lib_name, cflags, ldflags)"
      f.puts "exec(compiler, *args)"
    end
    FileUtils.chmod "a+x", wrapper
  end

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
