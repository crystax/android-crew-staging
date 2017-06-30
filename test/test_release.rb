require 'minitest/unit'
require_relative '../library/release.rb'

class TestRelease < MiniTest::Test

  def test_initialize
    # empty ctor
    r = Release.new
    assert_equal(nil,   r.version)
    assert_equal(nil,   r.crystax_version)
    assert_equal(nil,   r.installed_crystax_version)
    assert_equal(nil,   r.installed?)
    assert_equal(nil,   r.source_installed?)

    # one argument
    r = Release.new('1.2.3')
    assert_equal('1.2.3', r.version)
    assert_equal(nil,     r.crystax_version)
    assert_equal(nil,     r.installed_crystax_version)
    assert_equal(nil,     r.installed?)
    assert_equal(nil,     r.source_installed?)

    # two arguments
    r = Release.new('4.5.0', 7)
    assert_equal('4.5.0', r.version)
    assert_equal(7,       r.crystax_version)
    assert_equal(nil,     r.installed_crystax_version)
    assert_equal(nil,     r.installed?)
    assert_equal(nil,     r.source_installed?)
  end

  def test_installed_set
    r = Release.new
    #
    r.installed = 5
    assert_equal(5,    r.installed_crystax_version)
    assert_equal(true, r.installed?)
    assert_equal(nil,  r.source_installed?)
    #
    r.installed = false
    assert_equal(nil,   r.installed_crystax_version)
    assert_equal(false, r.installed?)
    assert_equal(nil  , r.source_installed?)
    #
    r.source_installed = 6
    assert_equal(6,     r.installed_crystax_version)
    assert_equal(false, r.installed?)
    assert_equal(true,  r.source_installed?)
    #
    r.source_installed = false
    assert_equal(nil,   r.installed_crystax_version)
    assert_equal(false, r.installed?)
    assert_equal(false,  r.source_installed?)
    #
    r.installed = 7
    r.source_installed = 7
    assert_equal(7,    r.installed_crystax_version)
    assert_equal(true, r.installed?)
    assert_equal(true, r.source_installed?)
    #
    r.installed = false
    assert_equal(7,     r.installed_crystax_version)
    assert_equal(false, r.installed?)
    assert_equal(true,  r.source_installed?)
    #
    r.source_installed = false
    assert_equal(nil,   r.installed_crystax_version)
    assert_equal(false, r.installed?)
    assert_equal(false, r.source_installed?)
    #
    assert_raises(RuntimeError) { r.installed = true }
    assert_raises(RuntimeError) { r.source_installed = true }
  end

  def test_update
    r1 = Release.new
    h1 = { version: '1' }
    r1.update h1
    assert_equal('1', r1.version)
    #
    r2 = Release.new
    h2 = { version: '2', crystax_version: 2 }
    r2.update h2
    assert_equal('2', r2.version)
    assert_equal(2,   r2.crystax_version)
    #
    r3 = Release.new
    h3 = { version: '3', crystax_version: 3, installed_crystax_version: 2 }
    r3.update h3
    assert_equal('3', r3.version)
    assert_equal(3,   r3.crystax_version)
    assert_equal(2,   r3.installed_crystax_version)
  end

  def test_match
    r0 = Release.new
    r1 = Release.new('1.1.0')
    r2 = Release.new('1.1.0', 2)
    r3 = Release.new('1.1.0', 3)
    r4 = Release.new('1.1.0', 4, '4')
    r5 = Release.new('4.1.2')
    r6 = Release.new('4.1.2', 1)
    r7 = Release.new('4.1.2', 2)
    r8 = Release.new('4.1.2', 2, '5')

    assert_equal(true,  r0.match?(r0))
    assert_equal(true,  r0.match?(r1))
    assert_equal(true,  r0.match?(r2))
    assert_equal(true,  r0.match?(r3))
    assert_equal(true,  r0.match?(r4))
    assert_equal(true,  r0.match?(r5))
    assert_equal(true,  r0.match?(r6))
    assert_equal(true,  r0.match?(r7))
    assert_equal(true,  r0.match?(r8))

    assert_equal(true,  r1.match?(r0))
    assert_equal(true,  r1.match?(r1))
    assert_equal(true,  r1.match?(r2))
    assert_equal(true,  r1.match?(r3))
    assert_equal(true,  r1.match?(r4))
    assert_equal(false, r1.match?(r5))
    assert_equal(false, r1.match?(r6))
    assert_equal(false, r1.match?(r7))
    assert_equal(false, r1.match?(r8))

    assert_equal(true,  r2.match?(r0))
    assert_equal(true,  r2.match?(r1))
    assert_equal(true,  r2.match?(r2))
    assert_equal(true,  r2.match?(r3))
    assert_equal(true,  r2.match?(r4))
    assert_equal(false, r2.match?(r5))
    assert_equal(false, r2.match?(r6))
    assert_equal(false, r2.match?(r7))
    assert_equal(false, r2.match?(r8))

    assert_equal(true,  r3.match?(r0))
    assert_equal(true,  r3.match?(r1))
    assert_equal(true,  r3.match?(r2))
    assert_equal(true,  r3.match?(r3))
    assert_equal(true,  r3.match?(r4))
    assert_equal(false, r3.match?(r5))
    assert_equal(false, r3.match?(r6))
    assert_equal(false, r3.match?(r7))
    assert_equal(false, r3.match?(r8))

    assert_equal(true,  r4.match?(r0))
    assert_equal(true,  r4.match?(r1))
    assert_equal(true,  r4.match?(r2))
    assert_equal(true,  r4.match?(r3))
    assert_equal(true,  r4.match?(r4))
    assert_equal(false, r4.match?(r5))
    assert_equal(false, r4.match?(r6))
    assert_equal(false, r4.match?(r7))
    assert_equal(false, r4.match?(r8))

    assert_equal(true,  r5.match?(r0))
    assert_equal(false, r5.match?(r1))
    assert_equal(false, r5.match?(r2))
    assert_equal(false, r5.match?(r3))
    assert_equal(false, r5.match?(r4))
    assert_equal(true,  r5.match?(r5))
    assert_equal(true,  r5.match?(r6))
    assert_equal(true,  r5.match?(r7))
    assert_equal(true,  r5.match?(r8))

    assert_equal(true,  r6.match?(r0))
    assert_equal(false, r6.match?(r1))
    assert_equal(false, r6.match?(r2))
    assert_equal(false, r6.match?(r3))
    assert_equal(false, r6.match?(r4))
    assert_equal(true,  r6.match?(r5))
    assert_equal(true,  r6.match?(r6))
    assert_equal(true,  r6.match?(r7))
    assert_equal(true,  r6.match?(r8))

    assert_equal(true,  r7.match?(r0))
    assert_equal(false, r7.match?(r1))
    assert_equal(false, r7.match?(r2))
    assert_equal(false, r7.match?(r3))
    assert_equal(false, r7.match?(r4))
    assert_equal(true,  r7.match?(r5))
    assert_equal(true,  r7.match?(r6))
    assert_equal(true,  r7.match?(r7))
    assert_equal(true,  r7.match?(r8))

    assert_equal(true,  r8.match?(r0))
    assert_equal(false, r8.match?(r1))
    assert_equal(false, r8.match?(r2))
    assert_equal(false, r8.match?(r3))
    assert_equal(false, r8.match?(r4))
    assert_equal(true,  r8.match?(r5))
    assert_equal(true,  r8.match?(r6))
    assert_equal(true,  r8.match?(r7))
    assert_equal(true,  r8.match?(r8))
  end

  def test_to_s
    r = Release.new
    assert_equal(r.to_s, '_')
    #
    r = Release.new('2.0.0')
    assert_equal(r.to_s, '2.0.0_')
    # two arguments
    r = Release.new('3.3.0', 3)
    assert_equal(r.to_s, '3.3.0_3')
    # three arguments
    r = Release.new('24.5.1', 4, '1812')
    assert_equal(r.to_s, '24.5.1_4')
  end
end
