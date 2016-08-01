require_relative 'global.rb'

class Platform

  NAMES = ['darwin-x86_64', 'linux-x86_64', 'windows-x86_64', 'windows']
  MACOSX_VERSION_MIN = '10.6'
  TOOLCHAIN = { 'darwin'  => { tool_path:   "#{Global::PLATFORM_PREBUILTS_DIR}/gcc/darwin-x86/host/x86_64-apple-darwin-4.9.3/bin",
                               tool_prefix: '',
                               gcc:         'gcc',
                               gxx:         'g++',
                               ar:          'gcc-ar',
                               ranlib:      'gcc-ranlib'
                             },
                'linux'   => { tool_path:   "#{Global::PLATFORM_PREBUILTS_DIR}/gcc/linux-x86/host/x86_64-linux-glibc2.11-4.8/bin",
                               tool_prefix: 'x86_64-linux-',
                               gcc:         'gcc',
                               gxx:         'g++',
                               ar:          'ar',
                               ranlib:      'ranlib'
                             },
                'windows' => { tool_path:   "#{Global::PLATFORM_PREBUILTS_DIR}/gcc/linux-x86/host/x86_64-w64-mingw32-4.9.3/bin",
                               tool_prefix: 'x86_64-w64-mingw32-',
                               gcc:         'gcc',
                               gxx:         'g++',
                               ar:          'ar',
                               ranlib:      'ranlib',
                             }
              }

  attr_reader :name, :target_os, :target_cpu, :cc, :cxx, :ar, :ranlib, :cflags, :cxxflags, :configure_host

  def initialize(name)
    raise "unsupported platform #{name}" unless NAMES.include? name

    @name = name
    @target_os, @target_cpu = name.split('-')
    @target_cpu = 'x86' if @target_cpu == nil
    #
    toolchain = TOOLCHAIN[@target_os]
    path = toolchain[:tool_path]
    prefix = toolchain[:tool_prefix]
    @cc = File.join(path, "#{prefix}#{toolchain[:gcc]}")
    @cxx = File.join(path, "#{prefix}#{toolchain[:gxx]}")
    if @target_os == 'darwin'
      # there is a problenm with lt_plugin on darwin
      @ar = 'ar'
      @ranlib = 'ranlib'
    else
      @ar = File.join(path, "#{prefix}#{toolchain[:ar]}")
      @ranlib = File.join(path, "#{prefix}#{toolchain[:ranlib]}")
    end
    #
    @cflags = init_cflags
    @cxxflags = @cflags
    @configure_host = init_configure_host
  end

  def to_sym
    @name.gsub(/-/, '_').to_sym
  end

  def target_name
    @name == 'windows-x86' ? 'windows' : @name
  end

  private

  def init_cflags
    case @name
    when 'darwin-x86_64'  then "-isysroot#{Global::PLATFORM_PREBUILTS_DIR}/sysroot/darwin-x86/MacOSX10.6.sdk -mmacosx-version-min=#{MACOSX_VERSION_MIN} -DMAXOSX_DEPLOYEMENT_TARGET=#{MACOSX_VERSION_MIN} -m64"
    when 'linux-x86_64'   then "--sysroot=#{Global::PLATFORM_PREBUILTS_DIR}/gcc/linux-x86/host/x86_64-linux-glibc2.11-4.8/sysroot"
    when 'windows-x86_64' then '-m64'
    when 'windows'        then '-m32'
    end
  end

  def init_configure_host
    case @name
    when 'darwin-x86_64'  then 'x86_64-darwin10'
    when 'linux-x86_64'   then 'x86_64-linux'
    when 'windows-x86_64' then 'x86_64-w64-mingw32'
    when 'windows'        then 'x86_64-w64-mingw32'
    end
  end

  # def init_cc
  #   # todo: clang from platform/prebuilts builds ruby with not working psych library (gem install fails)
  #   # File.join(Common::NDK_ROOT_DIR, "platform/prebuilts/clang/darwin-x86/host/x86_64-apple-darwin-3.7.0/bin/clang")
  #   #when 'darwin'  then 'clang'
  #   case @target_os
  #   when 'darwin'  then "#{Global::PLATFORM_PREBUILTS_DIR}/gcc/darwin-x86/host/x86_64-apple-darwin-4.9.3/bin/gcc"
  #   when 'linux'   then "#{Global::PLATFORM_PREBUILTS_DIR}/gcc/linux-x86/host/x86_64-linux-glibc2.11-4.8/bin/x86_64-linux-gcc"
  #   when 'windows' then "#{Global::PLATFORM_PREBUILTS_DIR}/gcc/linux-x86/host/x86_64-w64-mingw32-4.9.3/bin/x86_64-w64-mingw32-gcc"
  #   end
  # end

  # def init_cxx
  #   # todo: clang from platform/prebuilts builds ruby with not working psych library (gem install fails)
  #   # File.join(Common::NDK_ROOT_DIR, "platform/prebuilts/clang/darwin-x86/host/x86_64-apple-darwin-3.7.0/bin/clang")
  #   #when 'darwin'  then 'clang++'
  #   case @target_os
  #   when 'darwin'  then "#{Global::PLATFORM_PREBUILTS_DIR}/gcc/darwin-x86/host/x86_64-apple-darwin-4.9.3/bin/g++"
  #   when 'linux'   then "#{Global::PLATFORM_PREBUILTS_DIR}/gcc/linux-x86/host/x86_64-linux-glibc2.11-4.8/bin/x86_64-linux-g++"
  #   when 'windows' then "#{Global::PLATFORM_PREBUILTS_DIR}/gcc/linux-x86/host/x86_64-w64-mingw32-4.9.3/bin/x86_64-w64-mingw32-g++"
  #   end
  # end
end
