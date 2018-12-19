require 'minitest/unit'
require_relative '../library/exceptions.rb'
require_relative '../library/cmd/info/options.rb'

class TestInfoOptions < MiniTest::Test

  def test_initialize
    # empty ctor
    v = Crew::Info::Options.new([])
    assert_equal(:all, v.show_info)

    # only --versions-only
    v = Crew::Info::Options.new(['--versions-only'])
    assert_equal(:versions, v.show_info)

    # only --path-only
    v = Crew::Info::Options.new(['--path-only'])
    assert_equal(:path, v.show_info)

    # both options 1
    v = Crew::Info::Options.new(['--versions-only', '--path-only'])
    assert_equal(:path, v.show_info)

    # both options 2
    v = Crew::Info::Options.new(['--path-only', '--versions-only'])
    assert_equal(:versions, v.show_info)

    # unknown option
    assert_raises(UnknownOption) { Crew::Info::Options.new(['--hello-world']) }
  end
end
