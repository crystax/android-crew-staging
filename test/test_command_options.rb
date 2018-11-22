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
end
