require 'minitest/unit'
require_relative '../library/exceptions.rb'
require_relative '../library/cmd/test/options.rb'

class TestTestOptions < MiniTest::Test

  def test_initialize
    def_abis = Arch::ABI_LIST
    def_num_jobs = Utils.processor_count * 2
    def_types = ['build']
    def_toolchains = (Toolchain::SUPPORTED_GCC + Toolchain::SUPPORTED_LLVM).map(&:to_s)

    # empty ctor
    v = Crew::Test::Options.new([])
    assert_equal(def_abis,       v.abis)
    assert_equal(def_num_jobs,   v.num_jobs)
    assert_equal(def_types,      v.types)
    assert_equal(def_toolchains, v.toolchains)
    assert_equal(false,          v.all_versions?)

    # all options
    v = Crew::Test::Options.new(['--num-jobs=1', '--abis=arm64-v8a', '--types=build,run', '--toolchains=gcc6,llvm3.8', '--all-versions'])
    assert_equal(['arm64-v8a'],       v.abis)
    assert_equal(1,                   v.num_jobs)
    assert_equal(['build', 'run'],    v.types)
    assert_equal(['gcc6', 'llvm3.8'], v.toolchains)
    assert_equal(true,                v.all_versions?)

    # bad toolchain
    assert_raises(RuntimeError) { Crew::Test::Options.new(['--toolchains=gcc']) }

    # bad type
    assert_raises(UnknownOption) { Crew::Test::Options.new(['--types=test']) }

    # unknown option
    assert_raises(UnknownOption) { Crew::Test::Options.new(['--unknown-option']) }
  end
end
