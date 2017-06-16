class Arch

  attr_reader :name, :num_bits, :min_api_level, :default_lib_dir, :host, :toolchain, :abis, :abis_to_build

  def self.supported?(arch_name)
    NAMES.values.include? arch_name
  end

  def initialize(name, bits, min_api, default_lib_dir, host, toolchain, abis)
    @name = name
    @num_bits = bits
    @min_api_level = min_api
    @default_lib_dir = default_lib_dir
    @host = host
    @toolchain = toolchain
    @abis = abis
    @abis_to_build = []
  end

  def abis_to_build=(v)
    v.each do |abi|
      raise "unsupported abi #{abi} for #{@name}" unless @abis.include? abi
      @abis_to_build << abi
    end
  end

  def dup
    arch = Arch.new(name, num_bits, min_api_level, default_lib_dir, host, toolchain, abis)
    arch.abis_to_build = abis_to_build.dup
    arch
  end

  def to_s
    @name
  end

  MIN_32_API_LEVEL = 9
  MIN_64_API_LEVEL = 21

  NAMES = { arm: 'arm', x86: 'x86', mips: 'mips', arm64: 'arm64', x86_64: 'x86_64', mips64: 'mips64' }

  ARM    = Arch.new(NAMES[:arm],    32, MIN_32_API_LEVEL, 'lib',   'arm-linux-androideabi',  'arm-linux-androideabi',  ['armeabi-v7a', 'armeabi-v7a-hard']).freeze
  X86    = Arch.new(NAMES[:x86],    32, MIN_32_API_LEVEL, 'lib',   'i686-linux-android',     'x86',                    ['x86']).freeze
  MIPS   = Arch.new(NAMES[:mips],   32, MIN_32_API_LEVEL, 'lib',   'mipsel-linux-android',   'mipsel-linux-android',   ['mips']).freeze
  ARM64  = Arch.new(NAMES[:arm64],  64, MIN_64_API_LEVEL, 'lib',   'aarch64-linux-android',  'aarch64-linux-android',  ['arm64-v8a']).freeze
  X86_64 = Arch.new(NAMES[:x86_64], 64, MIN_64_API_LEVEL, 'lib64', 'x86_64-linux-android',   'x86_64',                 ['x86_64']).freeze
  MIPS64 = Arch.new(NAMES[:mips64], 64, MIN_64_API_LEVEL, 'lib64', 'mips64el-linux-android', 'mips64el-linux-android', ['mips64']).freeze

  LIST     = { arm: ARM, x86: X86, mips: MIPS, arm64: ARM64, x86_74: X86_64, mips64: MIPS64 }
  ABI_LIST = LIST.values.map { |a| a.abis }.flatten
end
