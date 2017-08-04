require 'minitest/unit'
require_relative '../library/utils.rb'

class TestUtils < MiniTest::Test

  def test_split_archive_path
    # package with usual version
    filename, release_str, platform_name = Utils.split_archive_path('/var/tmp/crew-pkg-cache/packages/bash-4.3.30_1.tar.xz')
    assert_equal('bash',     filename)
    assert_equal('4.3.30_1', release_str)
    assert_equal('android',  platform_name)

    # package with unusual version
    filename, release_str, platform_name = Utils.split_archive_path('/var/tmp/crew-pkg-cache/packages/pack-a-b-c_1.tar.xz')
    assert_equal('pack',     filename)
    assert_equal('a-b-c_1', release_str)
    assert_equal('android',  platform_name)

    # tool with usual version and platform
    filename, release_str, platform_name = Utils.split_archive_path('/var/tmp/crew-pkg-cache/tools/ruby-2.2.2_1-darwin-x86_64.tar.xz')
    assert_equal('ruby',          filename)
    assert_equal('2.2.2_1',       release_str)
    assert_equal('darwin-x86_64', platform_name)

    # tool with unusual version and platform
    filename, release_str, platform_name = Utils.split_archive_path('/var/tmp/crew-pkg-cache/tools/libedit-20150325-3.1_1-darwin-x86_64.tar.xz')
    assert_equal('libedit',        filename)
    assert_equal('20150325-3.1_1', release_str)
    assert_equal('darwin-x86_64',  platform_name)

    # bad extension
    assert_raises(RuntimeError) { Utils.split_archive_path('/var/tmp/crew-pkg-cache/packages/bash-4.3.30_1.zip') }

    # bad archive type
    assert_raises(RuntimeError) { Utils.split_archive_path('/var/tmp/crew-pkg-cache/archives/bash-4.3.30_1.tar.xz') }

    # bad package filename
    assert_raises(RuntimeError) { Utils.split_archive_path('/var/tmp/crew-pkg-cache/packages/bash.tar.xz') }

    # bad tool filename
    assert_raises(RuntimeError) { Utils.split_archive_path('/var/tmp/crew-pkg-cache/tools/tool-1.0.0_1.tar.xz') }

  end

  def test_split_package_version
    r = Release.new('1.2.3', 4)
    ver, cxver = Utils.split_package_version(r.to_s)
    assert_equal(r.version,         ver)
    assert_equal(r.crystax_version, cxver)
  end
end
