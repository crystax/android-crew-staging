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

  attr_reader :name, :target_os, :target_cpu, :cc, :cxx, :ar, :ranlib, :cflags, :cxxflags, :configure_host #:toolchain_host, :toolchain_build

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
    case @name
    when 'darwin-x86_64'
      @cflags          = "-isysroot#{Global::PLATFORM_PREBUILTS_DIR}/sysroot/darwin-x86/MacOSX10.6.sdk -mmacosx-version-min=#{MACOSX_VERSION_MIN} -DMAXOSX_DEPLOYEMENT_TARGET=#{MACOSX_VERSION_MIN} -m64"
      @configure_host  = 'x86_64-darwin10'
      # @toolchain_host  = 'x86_64-apple-darwin'
      # @toolchain_build = @toolchain_host
    when 'linux-x86_64'
      @cflags          = "--sysroot=#{Global::PLATFORM_PREBUILTS_DIR}/gcc/linux-x86/host/x86_64-linux-glibc2.11-4.8/sysroot"
      @configure_host  = 'x86_64-linux'
      # @toolchain_host  = 'x86_64-linux-gnu'
      # @toolchain_build = @toolchain_host
    when 'windows-x86_64'
      @cflags          = '-m64'
      @configure_host  = 'x86_64-w64-mingw32'
      # @toolchain_host  = 'x86_64-pc-mingw32msvc'
      # @toolchain_build = 'i686-pc-cygwin'
    when 'windows'
      @cflags          = '-m32'
      @configure_host  = 'x86_64-w64-mingw32'
      # @toolchain_host  = 'i586-pc-mingw32msvc'
      # @toolchain_build = 'i686-pc-cygwin'
    end

    @cxxflags = @cflags
  end

  def to_sym
    @name.gsub(/-/, '_').to_sym
  end

  def target_name
    @name == 'windows-x86' ? 'windows' : @name
  end
end
