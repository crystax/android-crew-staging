require 'minitest/unit'
require_relative '../library/utils.rb'

class TestUtils < MiniTest::Test

  def test_split_package_version
    r = Release.new('1.2.3', 4)
    ver, cxver = Utils.split_package_version(r.to_s)
    assert_equal(r.version,         ver)
    assert_equal(r.crystax_version, cxver)
  end
end
