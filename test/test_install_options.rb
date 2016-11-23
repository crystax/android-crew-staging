require 'minitest/unit'
require_relative '../library/global.rb'
require_relative '../library/install_options.rb'

class TestRelease < MiniTest::Test

  def test_initialize
    # empty ctor
    h = { platform: Global::PLATFORM_NAME, check_shasum: true, cache_only: false }
    v = Install_options.new([])
    assert_equal(Global::PLATFORM_NAME, v.platform)
    assert_equal(true,                  v.check_shasum?)
    assert_equal(false,                 v.cache_only?)
    assert_equal(h,                     v.as_hash)
    # all options
    h = { platform: 'darwin-x86_64', check_shasum: false, cache_only: true }
    v = Install_options.new(['--no-check-shasum', '--platform=darwin-x86_64', '--cache-only'])
    assert_equal('darwin-x86_64', v.platform)
    assert_equal(false,           v.check_shasum?)
    assert_equal(true,            v.cache_only?)
    assert_equal(h,               v.as_hash)
    # unknown option
    assert_raises(RuntimeError) { Install_options.new(['--hello-world']) }
  end
end
