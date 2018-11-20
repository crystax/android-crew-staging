require 'minitest/unit'
require_relative '../library/global.rb'
require_relative '../library/cmd/install/options.rb'

class TestInstallOptions < MiniTest::Test

  def test_initialize
    # empty ctor
    h = { platform: Global::PLATFORM_NAME, check_shasum: true, cache_only: false, force: false, all_versions: false, with_dev_files: false }
    v = Crew::Install::Options.new([])
    assert_equal(Global::PLATFORM_NAME, v.platform)
    assert_equal(true,                  v.check_shasum?)
    assert_equal(false,                 v.cache_only?)
    assert_equal(false,                 v.force?)
    assert_equal(false,                 v.all_versions?)
    assert_equal(false,                 v.with_dev_files?)
    assert_equal(h,                     v.as_hash)

    # all options
    h = { platform: 'darwin-x86_64', check_shasum: false, cache_only: true, force: true, all_versions: true, with_dev_files: true }
    v = Crew::Install::Options.new(['--no-check-shasum', '--platform=darwin-x86_64', '--cache-only', '--all-versions', '--force', '--with-dev-files'])
    assert_equal('darwin-x86_64', v.platform)
    assert_equal(false,           v.check_shasum?)
    assert_equal(true,            v.cache_only?)
    assert_equal(true,            v.force?)
    assert_equal(true,            v.all_versions?)
    assert_equal(true,            v.with_dev_files?)
    assert_equal(h,               v.as_hash)

    # unknown option
    assert_raises(RuntimeError) { Crew::Install::Options.new(['--hello-world']) }
  end
end
