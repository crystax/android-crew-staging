require 'minitest/unit'
require_relative '../library/exceptions.rb'
require_relative '../library/cmd/make_deb/options.rb'

class TestMakeDebOptions < MiniTest::Test

  def test_initialize
    # empty ctor
    v = Crew::MakeDeb::Options.new([])
    assert_equal(Global::DEB_CACHE_DIR,  v.deb_repo_base)
    assert_equal(Arch::ABI_LIST,         v.abis)
    assert_equal(false,                  v.all_versions?)
    assert_equal(true,                   v.clean?)
    assert_equal(true,                   v.check_shasum?)

    # all options
    v = Crew::MakeDeb::Options.new(['--deb-repo-base=/tmp/zzz', '--all-versions', '--abis=arm64-v8a', '--no-clean', '--no-check-shasum'])
    assert_equal('/tmp/zzz',    v.deb_repo_base)
    assert_equal(['arm64-v8a'], v.abis)
    assert_equal(true,          v.all_versions?)
    assert_equal(false,         v.clean?)
    assert_equal(false,         v.check_shasum?)

    # unknown option
    assert_raises(UnknownOption) { Crew::MakeDeb::Options.new(['--unknown-option']) }
  end
end
