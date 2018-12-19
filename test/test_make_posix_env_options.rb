require 'minitest/unit'
require_relative '../library/exceptions.rb'
require_relative '../library/cmd/make_posix_env/options.rb'

class TestMakePosixEnvOptions < MiniTest::Test

  def test_initialize
    # empty ctor
    assert_raises(RuntimeError) { Crew::MakePosixEnv::Options.new([]) }

    # with --top-dir
    assert_raises(RuntimeError) { Crew::MakePosixEnv::Options.new(['--top-dir=/tmp/posix']) }

    # with both required options
    v = Crew::MakePosixEnv::Options.new(['--top-dir=/tmp/posix', '--abi=arm64-v8a'])
    assert_equal('/tmp/posix', v.top_dir)
    assert_equal('arm64-v8a',  v.abi)
    assert_equal([],           v.with_packages)
    assert_equal(true,         v.make_tarball?)
    assert_equal(true,         v.check_shasum?)
    assert_equal(false,        v.minimize?)

    # with all options
    v = Crew::MakePosixEnv::Options.new(['--top-dir=/tmp/posix',
                                         '--abi=arm64-v8a',
                                         '--with-packages=erlang',
                                         '--no-tarball',
                                         '--no-check-shasum',
                                         '--minimize'
                                        ])
    assert_equal('/tmp/posix', v.top_dir)
    assert_equal('arm64-v8a',  v.abi)
    assert_equal(['erlang'],   v.with_packages)
    assert_equal(false,        v.make_tarball?)
    assert_equal(false,        v.check_shasum?)
    assert_equal(true,         v.minimize?)

    # unknown option
    assert_raises(UnknownOption) { Crew::MakePosixEnv::Options.new(['--unknown-option']) }
  end
end
