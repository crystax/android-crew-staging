require 'minitest/unit'
require_relative 'spec_consts.rb'
require_relative '../library/formulary.rb'
require_relative '../library/formula.rb'

class TestFormula < MiniTest::Test

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

  def test_simple_formula
    r1 = Release.new('1.0.0', 1, '0')
    f = Formulary.factory(File.join(Dir.pwd, Crew_test::DATA_DIR, 'simple.rb'))
    assert_equal('simple',                        f.name)
    assert_equal('Simple Formula',                f.desc)
    assert_equal('http://www.simple.formula.org', f.homepage)
    assert_equal(1,                               f.releases.size)
    assert_equal('1.0.0',                         f.releases[0].version)
    assert_equal(1,                               f.releases[0].crystax_version)
    assert_equal('0',                             f.releases[0].shasum)
    assert_equal([],                              f.dependencies)
    # todo:
    #assert_equal([],                              f.full_dependencies)
    # cache_file
    # install
    assert_equal(false,                           f.installed?)
    assert_equal(false,                           f.installed?(r1))
    assert_equal(false,                           f.source_installed?)
    assert_equal(false,                           f.source_installed?(r1))
  end
end
