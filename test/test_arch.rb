require 'minitest/unit'
require_relative '../library/arch.rb'

class TestRelease < MiniTest::Test

  def test_initialize
    arch = Arch.new('arm', 32, 9, 'lib', 'host', 'toolchain', ['abi1', 'abi2', 'abi3'])
    assert_equal('arm',                    arch.name)
    assert_equal(32,                       arch.num_bits)
    assert_equal(9,                        arch.min_api_level)
    assert_equal('lib',                    arch.default_lib_dir)
    assert_equal('host',                   arch.host)
    assert_equal('toolchain',              arch.toolchain)
    assert_equal(['abi1', 'abi2', 'abi3'], arch.abis)
    assert_equal([],                       arch.abis_to_build)
  end

  def test_setters
    arch = Arch.new('arm', 32, 9, 'lib', 'host', 'toolchain', ['abi1', 'abi2', 'abi3'])
    #
    arch.abis_to_build = ['abi1', 'abi2']
    assert_equal(['abi1', 'abi2'], arch.abis_to_build)
    #
    assert_raises(RuntimeError) { arch.abis_to_build = ['abi5'] }
  end

  def test_dup
    arch1 = Arch.new('arm', 32, 9, 'lib', 'host', 'toolchain', ['abi1', 'abi2', 'abi3'])
    arch1.abis_to_build = ['abi1']
    arch2 = arch1.dup
    assert_equal(arch1.name,            arch2.name)
    assert_equal(arch1.num_bits,        arch2.num_bits)
    assert_equal(arch1.min_api_level,   arch2.min_api_level)
    assert_equal(arch1.default_lib_dir, arch2.default_lib_dir)
    assert_equal(arch1.host,            arch2.host)
    assert_equal(arch1.toolchain,       arch2.toolchain)
    assert_equal(arch1.abis,            arch2.abis)
    assert_equal(arch1.abis_to_build,   arch2.abis_to_build)
    #
    arch1.abis_to_build = []
    assert_equal(['abi1'], arch2.abis_to_build)
  end
end
