require 'minitest/unit'
require_relative '../library/arch.rb'
require_relative '../library/cmd/command.rb'

class TestCommandOptions < MiniTest::Test

  def test_check_abi
    v = Crew::Command::Options.new

    # empty list
    assert_raises(RuntimeError) { v.check_abis }

    # 1 good abi
    v.check_abis Arch::ABI_LIST[0]

    # 2 good abis
    v.check_abis *Arch::ABI_LIST.slice(0, 2)

    # all possible abis
    v.check_abis *Arch::ABI_LIST.dup

    # 1 bad abi
    assert_raises(UnknownAbi) { v.check_abis 'abc' }

    # 2 bad abis
    assert_raises(UnknownAbi) { v.check_abis 'abc', 'def' }

    # 1 good and 1 bad abi
    assert_raises(UnknownAbi) { v.check_abis Arch::ABI_LIST[0], 'abc' }
  end

  def test_check_platform_names
    v = Crew::Command::Options.new

    # empty list
    assert_raises(RuntimeError) { v.check_platform_names }

    # 1 good platform
    v.check_platform_names Platform::NAMES[0]

    # 2 good platforms
    v.check_platform_names *Platform::NAMES.slice(0, 2)

    # all possible platforms
    v.check_platform_names *Platform::NAMES.dup

    # 1 bad platform
    assert_raises(UnknownPlatform) { v.check_platform_names 'a' }

    # 2 bad platforms
    assert_raises(UnknownPlatform) { v.check_platform_names 'a', 'b' }

    # 1 good and 1 bad platforms
    assert_raises(UnknownPlatform) { v.check_platform_names Platform::NAMES[0], 'a' }
  end
end
