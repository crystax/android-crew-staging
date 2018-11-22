require 'minitest/unit'
require_relative '../library/exceptions.rb'
require_relative '../library/arch.rb'
require_relative '../library/platform.rb'
require_relative '../library/utils.rb'
require_relative '../library/cmd/build/options.rb'

class TestBuildOptions < MiniTest::Test

  PLATFORMS = %w[darwin-x86_64 linux-x86_64 windows-x86_64 windows].map { |n| Platform.new(n) }

  def test_initialize
    # empty ctor
    v = Crew::Build::Options.new([])
    assert_equal(Arch::ABI_LIST,                     v.abis)
    assert_equal(false,                              v.source_only?)
    assert_equal(false,                              v.build_only?)
    assert_equal(true,                               v.install?)
    assert_equal(false,                              v.no_clean?)
    assert_equal(true,                               v.clean?)
    assert_equal(false,                              v.all_versions?)
    assert_equal(false,                              v.update_shasum?)
    assert_equal(Utils.processor_count * 2,          v.num_jobs)
    assert_equal(Platform.default_names_for_host_os, v.platforms)
    assert_equal(true,                               v.num_jobs_default?)

    PLATFORMS.each { |p| assert_equal(false, v.check?(p)) }


    # all options
    v = Crew::Build::Options.new(['--abis=x86',
                                  '--source-only',
                                  '--build-only',
                                  '--no-install',
                                  '--no-clean',
                                  '--check',
                                  '--all-versions',
                                  '--update-shasum',
                                  '--num-jobs=1',
                                  "--platforms=#{Global::PLATFORM_NAME}",
                                 ])
    assert_equal(['x86'],                 v.abis)
    assert_equal(true,                    v.source_only?)
    assert_equal(true,                    v.build_only?)
    assert_equal(false,                   v.install?)
    assert_equal(true,                    v.no_clean?)
    assert_equal(false,                   v.clean?)
    assert_equal(true,                    v.all_versions?)
    assert_equal(true,                    v.update_shasum?)
    assert_equal(1,                       v.num_jobs)
    assert_equal([Global::PLATFORM_NAME], v.platforms)
    assert_equal(false,                   v.num_jobs_default?)

    PLATFORMS.each { |p| assert_equal(p.target_os == Global::OS, v.check?(p)) }

    # connected options: source-only -> no-clean
    v = Crew::Build::Options.new(['--source-only'])
    assert_equal(true, v.source_only?)
    assert_equal(true, v.no_clean?)

    # connected options: build-only -> no-clean
    v = Crew::Build::Options.new(['--build-only'])
    assert_equal(true, v.build_only?)
    assert_equal(true, v.no_clean?)

    # connected options: num-jobs -> num_jobs_default?
    v = Crew::Build::Options.new(['--num-jobs=100'])
    assert_equal(100,   v.num_jobs)
    assert_equal(false, v.num_jobs_default?)

    # connected options: check -> num_jobs_default?
    v = Crew::Build::Options.new(['--num-jobs=100'])
    assert_equal(100,   v.num_jobs)
    assert_equal(false, v.num_jobs_default?)

    # unknown option
    assert_raises(UnknownOption) { Crew::Build::Options.new(['--hello-world']) }
  end
end
