require 'minitest/unit'
require_relative '../library/exceptions.rb'
require_relative '../library/cmd/build_check/options.rb'

class TestBuildCheckOptions < MiniTest::Test

  def test_initialize
    # empty ctor
    v = Crew::BuildCheck::Options.new([])
    assert_equal(false, v.show_bad_only?)

    # --show-bad-only
    v = Crew::BuildCheck::Options.new(['--show-bad-only'])
    assert_equal(true, v.show_bad_only?)

    # unknown option
    assert_raises(UnknownOption) { Crew::BuildCheck::Options.new(['--unknown-option']) }
  end
end
