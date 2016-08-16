class Arch
  attr_reader :name, :num_bits, :min_api_level, :host, :toolchain, :abis, :abis_to_build
  attr_accessor

  def initialize(name, bits, api, host, toolchain, abis)
    @name = name
    @num_bits = bits
    @min_api_level = api
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
    arch = Arch.new(name, num_bits, min_api_level, host, toolchain, abis)
    arch.abis_to_build = abis_to_build.dup
    arch
  end
end

MIN_32_API_LEVEL = 9
MIN_64_API_LEVEL = 21

ARCH_ARM    = Arch.new('arm',    32, MIN_32_API_LEVEL, 'arm-linux-androideabi',  'arm-linux-androideabi',  ['armeabi-v7a', 'armeabi-v7a-hard']).freeze
ARCH_X86    = Arch.new('x86',    32, MIN_32_API_LEVEL, 'i686-linux-android',     'x86',                    ['x86']).freeze
ARCH_MIPS   = Arch.new('mips',   32, MIN_32_API_LEVEL, 'mipsel-linux-android',   'mipsel-linux-android',   ['mips']).freeze
ARCH_ARM64  = Arch.new('arm64',  64, MIN_64_API_LEVEL, 'aarch64-linux-android',  'aarch64-linux-android',  ['arm64-v8a']).freeze
ARCH_X86_64 = Arch.new('x86_64', 64, MIN_64_API_LEVEL, 'x86_64-linux-android',   'x86_64',                 ['x86_64']).freeze
ARCH_MIPS64 = Arch.new('mips64', 64, MIN_64_API_LEVEL, 'mips64el-linux-android', 'mips64el-linux-android', ['mips64']).freeze
