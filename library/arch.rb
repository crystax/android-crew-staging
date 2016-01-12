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
