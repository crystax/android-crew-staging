require 'minitest/unit'
require_relative '../library/exceptions.rb'
require_relative '../library/cmd/source/options.rb'

class TestSourceOptions < MiniTest::Test

  def test_initialize
    # empty ctor
    v = Crew::Source::Options.new([])
    assert_equal(false, v.all_versions?)

    # only --all-versions
    v = Crew::Source::Options.new(['--all-versions'])
    assert_equal(true, v.all_versions?)

    # unknown option
    assert_raises(UnknownOption) { Crew::Source::Options.new(['--unknown-option']) }
  end
end
