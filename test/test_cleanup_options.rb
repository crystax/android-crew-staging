require 'minitest/unit'
require_relative '../library/exceptions.rb'
require_relative '../library/cmd/cleanup/options.rb'

class TestCleanupOptions < MiniTest::Test

  def test_initialize
    # empty ctor
    v = Crew::Cleanup::Options.new([])
    assert_equal(false, v.dry_run?)
    assert_equal(true, v.clean_pkg_cache?)
    assert_equal(true, v.clean_src_cache?)

    # only --dry-run
    v = Crew::Cleanup::Options.new(['--dry-run'])
    assert_equal(true, v.dry_run?)
    assert_equal(true, v.clean_pkg_cache?)
    assert_equal(true, v.clean_src_cache?)

    # only -n
    v = Crew::Cleanup::Options.new(['-n'])
    assert_equal(true, v.dry_run?)
    assert_equal(true, v.clean_pkg_cache?)
    assert_equal(true, v.clean_src_cache?)

    # only --pkg-cache
    v = Crew::Cleanup::Options.new(['--pkg-cache'])
    assert_equal(false, v.dry_run?)
    assert_equal(true,  v.clean_pkg_cache?)
    assert_equal(false, v.clean_src_cache?)

    # only --src-cache
    v = Crew::Cleanup::Options.new(['--src-cache'])
    assert_equal(false, v.dry_run?)
    assert_equal(false, v.clean_pkg_cache?)
    assert_equal(true,  v.clean_src_cache?)

    # unknown option
    assert_raises(UnknownOption) { Crew::Cleanup::Options.new(['--hello-world']) }
  end
end
