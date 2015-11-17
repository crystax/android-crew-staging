require 'minitest/unit'
require_relative '../library/formulary.rb'
require_relative '../library/formula.rb'

class TestRelease < MiniTest::Test

  def test_package_version
    r = Release.new('1.2.3', 4)
    assert_equal(r.to_s, Formula.package_version(r))
  end

  def test_split_package_version
    r1 = Release.new('1.2.3', 4)
    r2 = Formula.split_package_version(r1.to_s)
    assert_equal(r1.version,         r2.version)
    assert_equal(r1.crystax_version, r2.crystax_version)
    assert_equal(r1.shasum,          r2.shasum)
    assert_equal(r1.installed?,      r2.installed?)
  end

  # def test_simple_formula
  #   f = Formulary.factory('data/simple.rb')
  #   assert_equal(f.name, 'Simple')
  # end
end
