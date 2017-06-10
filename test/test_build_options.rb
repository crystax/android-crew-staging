require 'minitest/unit'
require_relative '../library/utils.rb'
require_relative '../library/cmd/build_options.rb'

class TestRelease < MiniTest::Test

  def test_initialize
    # empty ctor
    v = Build_options.new([])
    assert_equal(Build::ABI_LIST,           v.abis)
    assert_equal(Utils.processor_count * 2, v.num_jobs)
    assert_equal(false,                     v.build_only?)
    assert_equal(false,                     v.no_clean?)
    assert_equal(false,                     v.update_shasum?)
    assert_equal(false,                     v.all_versions?)
    # all options
    v = Build_options.new(['--abis=x86', '--num-jobs=1', '--build-only', '--no-clean', '--update-shasum', '--all-versions'])
    assert_equal(['x86'], v.abis)
    assert_equal(1,       v.num_jobs)
    assert_equal(true,    v.build_only?)
    assert_equal(true,    v.no_clean?)
    assert_equal(true,    v.update_shasum?)
    assert_equal(true,    v.all_versions?)
    # unknown option
    assert_raises(RuntimeError) { Build_options.new(['--hello-world']) }
  end

  def test_setters
    v = Build_options.new([])
    #
    v.abis = ['x86']
    assert_equal(['x86'], v.abis)
    #
    v.num_jobs = 1
    assert_equal(1, v.num_jobs)
    #
    v.build_only = true
    assert_equal(true, v.build_only?)
    #
    v.no_clean = true
    assert_equal(true, v.no_clean?)
    #
    v.update_shasum = true
    assert_equal(true, v.update_shasum?)
  end
end
