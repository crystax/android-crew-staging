require 'minitest/unit'
require_relative '../library/exceptions.rb'
require_relative '../library/cmd/upgrade/options.rb'

class TestUpradeOptions < MiniTest::Test

  def test_initialize
    # empty ctor
    v = Crew::Upgrade::Options.new([])
    assert_equal(true,  v.check_shasum?)
    assert_equal(false, v.dry_run?)

    # only -n
    v = Crew::Upgrade::Options.new(['-n'])
    assert_equal(true, v.check_shasum?)
    assert_equal(true, v.dry_run?)

    # all options
    v = Crew::Upgrade::Options.new(['--no-check-shasum', '--dry-run'])
    assert_equal(false, v.check_shasum?)
    assert_equal(true,  v.dry_run?)

    # unknown option
    assert_raises(UnknownOption) { Crew::Upgrade::Options.new(['--unknown-option']) }
  end
end
