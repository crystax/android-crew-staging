class Arch
  attr_reader :name, :num_bits, :min_api_level, :host, :toolchain, :abis
  attr_accessor :abis_to_build

  def initialize(name, bits, api, host, toolchain, abis)
    @name = name
    @num_bits = bits
    @min_api_level = api
    @host = host
    @toolchain = toolchain
    @abis = abis
    @abis_to_build = []
  end

  def dup
    arch = Arch.new(name, num_bits, min_api_level, host, toolchain, abis)
    arch.abis_to_build = abis_to_build.dup
    arch
  end
end
