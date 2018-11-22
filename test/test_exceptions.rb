require 'minitest/unit'
require_relative '../library/exceptions.rb'


class TestExceptions < MiniTest::Test

  def test_ErrorDuringExecution
    cmd = '/bin/command'
    error_text = 'file not found'

    # no error output
    v = ErrorDuringExecution.new('/bin/command', 5, '')
    assert_equal("Failure while executing: #{cmd}; exit code: 5", v.message)
    assert_equal(5, v.exit_code)
    assert_equal('', v.error_text)

    # with error ouput
    v = ErrorDuringExecution.new('/bin/command', 6, error_text)
    assert_equal("Failure while executing: #{cmd}; error output: #{error_text}; exit code: 6", v.message)
    assert_equal(6, v.exit_code)
    assert_equal(error_text, v.error_text)
  end

  def test_ReleaseNotFound
    # without crystax_version
    v = ReleaseNotFound.new('foo', Release.new('5.2.1'))
    assert_equal('foo has no release with version 5.2.1', v.message)

    # with crystax_version
    v = ReleaseNotFound.new('bar', Release.new('1.3.0', 4))
    assert_equal('bar has no release 1.3.0:4', v.message)
  end

  def test_DownloadError
    url = 'https://some.site/path/file.txt'
    text = 'no such file'

    # without error text
    v = DownloadError.new(url, 5)
    assert_equal(url, v.url)
    assert_equal(5,   v.error_code)
    assert_equal("failed to download #{url}: code: 5",  v.message)

    # with error text
    v = DownloadError.new(url, 5, text)
    assert_equal(url, v.url)
    assert_equal(5,   v.error_code)
    assert_equal("failed to download #{url}: code: 5; text: #{text}",  v.message)
  end

  def test_UnknownAbi
    # with one abi
    v = UnknownAbi.new('a')
    assert_equal('unknown abi: a', v.message)

    # with 3 abis
    v = UnknownAbi.new('a', 'b', 'c')
    assert_equal('unknown abis: a, b, c', v.message)
  end

  def test_UnknownPlatform
    # with one name
    v = UnknownPlatform.new('a')
    assert_equal('unknown platform: a', v.message)

    # with 2 names
    v = UnknownPlatform.new('a', 'b')
    assert_equal('unknown platforms: a, b', v.message)
  end
end
