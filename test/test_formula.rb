require 'minitest/unit'
require_relative '../library/formulary.rb'
require_relative '../library/formula.rb'

class TestRelease < MiniTest::Test

  def test_package_version
    r = Release.new('1.2.3', 4)
    assert_equal(r.to_s, Formula.package_version(r))
  end

  def test_split_package_version
    r = Release.new('1.2.3', 4)
    ver, cxver = Formula.split_package_version(r.to_s)
    assert_equal(r.version,         ver)
    assert_equal(r.crystax_version, cxver)
  end

  # def test_simple_formula
  #   f = Formulary.factory('data/simple.rb')
  #   assert_equal(f.name, 'Simple')
  # end
end
