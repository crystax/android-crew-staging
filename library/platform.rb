require_relative 'build.rb'

class Platform

  SUPPORTED_ON = Hash.new { |h, k| h[k] = [] }
  SUPPORTED_ON.update({ darwin: ['darwin-x86_64'],  linux: ['linux-x86_64', 'windows-x86_64', 'windows'] })

  NAMES = SUPPORTED_ON.values.flatten

  MACOSX_VERSION_MIN = '10.6'
  TOOLCHAIN = { 'darwin/darwin' => { tool_path:     "#{Build::PLATFORM_PREBUILTS_DIR}/gcc/darwin-x86/host/x86_64-apple-darwin-4.9.3/bin",
                                     tool_prefix:   '',
                                     major_version: 4,
                                     gcc:           'gcc',
                                     gxx:           'g++',
                                     # no ld in darwin/gcc toolchain
                                     ar:            'gcc-ar',
                                     ranlib:        'gcc-ranlib',
                                     # no strip in darwin/gcc toolchain
                                     nm:            'gcc-nm'
                                     # no windres
                                     # no dlltool
                                     # no dllwrap
                                   },
                'linux/linux'   => { tool_path:     "#{Build::PLATFORM_PREBUILTS_DIR}/gcc/linux-x86/host/x86_64-linux-glibc2.11-4.8/bin",
                                     tool_prefix:   'x86_64-linux-',
                                     major_version: 4,
                                     gcc:           'gcc',
                                     gxx:           'g++',
                                     ld:            'ld',
                                     ar:            'ar',
                                     ranlib:        'ranlib',
                                     strip:         'strip',
                                     nm:            'nm'
                                     # no windres
                                     # no dlltool
                                     # no dllwrap
                                   },
                'linux/darwin'  => { tool_path:     "#{Build::PLATFORM_PREBUILTS_DIR}/gcc/linux-x86/host/x86_64-apple-darwin10-4.9.4/bin",
                                     tool_prefix:   'x86_64-apple-darwin10-',
                                     major_version: 4,
                                     gcc:           'gcc',
                                     gxx:           'g++',
                                     ld:            'ld',
                                     ar:            'ar',
                                     ranlib:        'ranlib',
                                     strip:         'strip',
                                     nm:            'nm'
                                     # no windres
                                     # no dlltool
                                     # no dllwrap
                                   },
                # 'linux/darwin'  => { tool_path:     "#{Build::PLATFORM_PREBUILTS_DIR}/gcc/linux-x86/host/x86_64-apple-darwin10-6.3/bin",
                #                      tool_prefix:   'x86_64-apple-darwin10-',
                #                      major_version: 6,
                #                      gcc:           'gcc',
                #                      gxx:           'g++',
                #                      ld:            'ld',
                #                      ar:            'ar',
                #                      ranlib:        'ranlib',
                #                      strip:         'strip',
                #                      nm:            'nm'
                #                      # no windres
                #                      # no dlltool
                #                      # no dllwrap
                #                    },
                'linux/windows' => { tool_path:     "#{Build::PLATFORM_PREBUILTS_DIR}/gcc/linux-x86/host/x86_64-w64-mingw32-7.2/bin",
                                     tool_prefix:   'x86_64-w64-mingw32-',
                                     major_version: 7,
                                     gcc:           'gcc',
                                     gxx:           'g++',
                                     ld:            'ld',
                                     ar:            'ar',
                                     ranlib:        'ranlib',
                                     strip:         'strip',
                                     nm:            'nm',
                                     windres:       'windres',
                                     dlltool:       'dlltool',
                                     dllwrap:       'dllwrap'
                                   }
              }

  def self.default_names_for_host_os
    SUPPORTED_ON[Global::OS.to_sym]
  end

  attr_reader :name, :host_os, :target_os, :target_cpu
  attr_reader :toolchain_path
  attr_reader :cc, :cxx, :ld, :ar, :ranlib, :strip, :nm, :windres, :dlltool, :dllwrap
  attr_reader :sysroot
  attr_reader :cflags, :cxxflags
  attr_reader :configure_host, :configure_build
  attr_reader :target_exe_ext

  def initialize(name)
    raise "unsupported platform #{name}" unless NAMES.include? name

    @name = name
    @host_os = Global::OS
    @target_os, @target_cpu = name.split('-')
    @target_cpu = 'x86' if @target_cpu == nil

    os_pair = "#{@host_os}/#{@target_os}"
    #raise "unsupported host OS / target OS pair: #{os_pair}" unless TOOLCHAIN[os_pair]
    # todo: use special toolchain class
    toolchain = TOOLCHAIN[os_pair]

    return unless toolchain

    prefix = toolchain[:tool_prefix]

    @toolchain_path = toolchain[:tool_path]

    @cc = File.join(@toolchain_path, "#{prefix}#{toolchain[:gcc]}")
    @cxx = File.join(@toolchain_path, "#{prefix}#{toolchain[:gxx]}")
    if @target_os == 'darwin' and @host_os == 'darwin'
      # use system ld
      @ld     = 'ld'
      # there is a problem with lt_plugin on darwin
      @ar     = 'ar'
      @ranlib = 'ranlib'
      @strip  = 'strip'
      @nm     = 'nm'
    else
      @ld     = File.join(@toolchain_path, "#{prefix}#{toolchain[:ld]}")
      @ar     = File.join(@toolchain_path, "#{prefix}#{toolchain[:ar]}")
      @ranlib = File.join(@toolchain_path, "#{prefix}#{toolchain[:ranlib]}")
      @strip  = File.join(@toolchain_path, "#{prefix}#{toolchain[:strip]}")
      @nm     = File.join(@toolchain_path, "#{prefix}#{toolchain[:nm]}")
    end
    if @target_os == 'windows'
      @windres  = File.join(@toolchain_path, "#{prefix}#{toolchain[:windres]}")
      @windres += ' -F pe-i386' if @target_cpu == 'x86'
      @dlltool  = File.join(@toolchain_path, "#{prefix}#{toolchain[:dlltool]}")
      @dllwrap  = File.join(@toolchain_path, "#{prefix}#{toolchain[:dllwrap]}")
    end

    case @name
    when 'darwin-x86_64'
      # openssl build fails if put a blank bettwen -isysroot and sysroot path
      # --sysroot can not be used here even for gcc, it will break almost all builds on darwin
      @sysroot         = "#{Build::PLATFORM_PREBUILTS_DIR}/sysroot/darwin-x86/MacOSX10.6.sdk"
      @cflags          = "-isysroot#{sysroot} -mmacosx-version-min=#{MACOSX_VERSION_MIN} -DMACOSX_DEPLOYMENT_TARGET=#{MACOSX_VERSION_MIN} -m64"
      @configure_host  = 'x86_64-apple-darwin10'
      @configure_build = (@host_os == 'darwin') ? @configure_host : 'x86_64-linux-gnu'
      #@toolchain_host  = 'x86_64-darwin10' #'x86_64-apple-darwin'
    when 'linux-x86_64'
      @sysroot         = "#{Build::PLATFORM_PREBUILTS_DIR}/gcc/linux-x86/host/x86_64-linux-glibc2.11-4.8/sysroot"
      @cflags          = "--sysroot=#{sysroot}"
      @configure_host  = 'x86_64-linux'
      @configure_build = 'x86_64-linux-gnu'
    when 'windows-x86_64'
      @cflags          = '-m64'
      @configure_host  = 'x86_64-w64-mingw32'
      @configure_build = 'x86_64-linux-gnu'
    when 'windows'
      @cflags          = '-m32'
      @configure_host  = 'i686-w64-mingw32'
      @configure_build = 'x86_64-linux-gnu'
    end

    @cxxflags = @cflags

    @target_exe_ext = (@target_os == 'windows') ? '.exe' : ''
  end

  def cross_compile?
    host_os != target_os
  end

  def configure_args
    cross_compile? ? ["--host=#{configure_host}", "--build=#{configure_build}"] : []
  end

  def to_sym
    @name.gsub(/-/, '_').to_sym
  end

  def target_name
    @name == 'windows-x86' ? 'windows' : @name
  end
end
