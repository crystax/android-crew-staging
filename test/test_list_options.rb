require 'minitest/unit'
require_relative '../library/exceptions.rb'
require_relative '../library/cmd/list/options.rb'

class TestListOptions < MiniTest::Test

  def test_initialize
    # empty ctor
    v = Crew::List::Options.new([])
    assert_equal(true,  v.list_tools?)
    assert_equal(true,  v.list_packages?)
    assert_equal(false, v.no_title?)
    assert_equal(false, v.names_only?)
    assert_equal(false, v.buildable_order?)

    # only --tools
    v = Crew::List::Options.new(['--tools'])
    assert_equal(true,  v.list_tools?)
    assert_equal(false, v.list_packages?)
    assert_equal(false, v.no_title?)
    assert_equal(false, v.names_only?)
    assert_equal(false, v.buildable_order?)

    # only --packages
    v = Crew::List::Options.new(['--packages'])
    assert_equal(false, v.list_tools?)
    assert_equal(true,  v.list_packages?)
    assert_equal(false, v.no_title?)
    assert_equal(false, v.names_only?)
    assert_equal(false, v.buildable_order?)

    # all options
    v = Crew::List::Options.new(['--tools', '--packages', '--no-title', '--names-only', '--buildable-order'])
    assert_equal(true, v.list_tools?)
    assert_equal(true, v.list_packages?)
    assert_equal(true, v.no_title?)
    assert_equal(true, v.names_only?)
    assert_equal(true, v.buildable_order?)

    # unknown option
    assert_raises(UnknownOption) { Crew::List::Options.new(['--unknown-option']) }
  end
end
