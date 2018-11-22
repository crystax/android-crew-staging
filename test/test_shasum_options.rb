require 'minitest/unit'
require_relative '../library/exceptions.rb'
require_relative '../library/cmd/shasum/options.rb'

class TestShasumOptions < MiniTest::Test

  def test_initialize
    # empty ctor
    v = Crew::Shasum::Options.new([])
    assert_equal([Global::PLATFORM_NAME], v.platforms)
    assert_equal(false, v.update?)
    assert_equal(true,  v.check?)

    # only --update
    v = Crew::Shasum::Options.new(['--update'])
    assert_equal([Global::PLATFORM_NAME], v.platforms)
    assert_equal(true,  v.update?)
    assert_equal(false, v.check?)

    # only --check
    v = Crew::Shasum::Options.new(['--check'])
    assert_equal([Global::PLATFORM_NAME], v.platforms)
    assert_equal(false, v.update?)
    assert_equal(true,  v.check?)

    p1 = Platform::NAMES[0]
    p2 = Platform::NAMES[1]

    # specify platforms
    v = Crew::Shasum::Options.new(["--platforms=#{p1},#{p2}"])
    assert_equal([p1, p2], v.platforms)
    assert_equal(false, v.update?)
    assert_equal(true,  v.check?)

    # platforms and update
    v = Crew::Shasum::Options.new(["--platforms=#{p1},#{p2}", '--update'])
    assert_equal([p1, p2], v.platforms)
    assert_equal(true,  v.update?)
    assert_equal(false, v.check?)

    # unknown option
    assert_raises(UnknownOption) { Crew::Shasum::Options.new(['--unknown-option']) }
  end
end
