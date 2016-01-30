require_relative 'global.rb'

class Platform

  NAMES = ['darwin-x86_64', 'darwin-x86', 'linux-x86_64', 'linux-x86', 'windows-x86_64', 'windows']
  MACOSX_VERSION_MIN = '10.6'

  attr_reader :name, :target_os, :target_cpu, :cc, :cflags, :configure_host

  def initialize(name)
    raise "unsupported platform #{name}" unless NAMES.include? name

    @name = name
    @target_os, @target_cpu = name.split('-')
    @cc = init_cc
    @cflags = init_cflags
    @configure_host = init_configure_host
  end

  def to_sym
    @name.gsub(/-/, '_').to_sym
  end

  private

  def init_cc
    # todo: clang from platform/prebuilts builds ruby with not working psych library (gem install fails)
    # File.join(Common::NDK_ROOT_DIR, "platform/prebuilts/clang/darwin-x86/host/x86_64-apple-darwin-3.7.0/bin/clang")
    case @target_os
    when 'darwin'  then 'clang'
    when 'linux'   then "#{Global::PLATFORM_PREBUILTS_DIR}/gcc/linux-x86/host/x86_64-linux-glibc2.11-4.8/bin/x86_64-linux-gcc"
    when 'windows' then "#{Global::PLATFORM_PREBUILTS_DIR}/gcc/linux-x86/host/x86_64-w64-mingw32-4.8/bin/x86_64-w64-mingw32-gcc"
    end
  end

  def init_cflags
    case @name
    when 'darwin-x86_64'  then "-isysroot#{Global::PLATFORM_PREBUILTS_DIR}/sysroot/darwin-x86/MacOSX10.6.sdk -mmacosx-version-min=#{MACOSX_VERSION_MIN} -m64"
    when 'darwin-x86'     then "-isysroot#{Global::PLATFORM_PREBUILTS_DIR}/sysroot/darwin-x86/MacOSX10.6.sdk -mmacosx-version-min=#{MACOSX_VERSION_MIN} -m32"
    when 'linux-x86_64'   then "--sysroot=#{Global::PLATFORM_PREBUILTS_DIR}/gcc/linux-x86/host/x86_64-linux-glibc2.11-4.8/sysroot"
    when 'linux-x86'      then "--sysroot=#{Global::PLATFORM_PREBUILTS_DIR}/gcc/linux-x86/host/x86_64-linux-glibc2.11-4.8/sysroot -m32"
    when 'windows-x86_64' then '-m64'
    when 'windows'        then '-m32'
    end
  end

  def init_configure_host
    case @name
    when 'darwin-x86_64'  then 'x86_64-darwin10'
    when 'darwin-x86'     then 'i686-darwin10'
    when 'linux-x86_64'   then 'x86_64-linux'
    when 'linux-x86'      then 'i686-linux'
    when 'windows-x86_64' then 'x86_64-w64-mingw32'
    when 'windows'        then 'x86_64-w64-mingw32'
    end
  end
end
