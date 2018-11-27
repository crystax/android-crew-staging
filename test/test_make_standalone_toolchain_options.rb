require 'minitest/unit'
require_relative '../library/exceptions.rb'
require_relative '../library/cmd/make_standalone_toolchain/options.rb'

class TestMakeStandaloneToolchainOptions < MiniTest::Test

  def test_initialize
    # empty ctor
    assert_raises(RuntimeError) { Crew::MakeStandaloneToolchain::Options.new([]) }

    # with --arch
    assert_raises(RuntimeError) { Crew::MakeStandaloneToolchain::Options.new(['--arch=arm64']) }

    arch = Arch::ARM64
    def_gcc = Toolchain::DEFAULT_GCC
    def_llvm = Toolchain::DEFAULT_LLVM
    def_platform = Platform.new(Global::PLATFORM_NAME)

    # with both required options
    v = Crew::MakeStandaloneToolchain::Options.new(['--arch=arm64', '--install-dir=/tmp/toolchain'])
    assert_equal('/tmp/toolchain',   v.install_dir)
    assert_equal(arch,               v.arch)
    assert_equal(def_gcc,            v.gcc)
    assert_equal(def_llvm,           v.llvm)
    assert_equal('gnustl',           v.stl)
    assert_equal(def_platform.name,  v.platform.name)
    assert_equal(arch.min_api_level, v.api_level)
    assert_equal([],                 v.with_packages)

    # with all options
    llvm3_6_gcc6 = Toolchain::LLVM.new('3.6', Toolchain::GCC_6)
    v = Crew::MakeStandaloneToolchain::Options.new(['--arch=arm64',
                                                    '--install-dir=/tmp/toolchain',
                                                    '--gcc-version=6',
                                                    '--llvm-version=3.6',
                                                    '--stl=libc++',
                                                    "--platform=#{def_platform.name}",
                                                    '--api-level=21',
                                                    '--with-packages=erlang'
                                                   ])
    assert_equal('/tmp/toolchain',    v.install_dir)
    assert_equal(arch,                v.arch)
    assert_equal(Toolchain::GCC_6,    v.gcc)
    assert_equal(llvm3_6_gcc6,        v.llvm)
    assert_equal('libc++',            v.stl)
    assert_equal(def_platform.name,   v.platform.name)
    assert_equal(21,                  v.api_level)
    assert_equal('erlang',            v.with_packages[0].name)

    # without --clean-install-dir and existing install dir
    Dir.mktmpdir do |dir|
      assert_raises(RuntimeError) { Crew::MakeStandaloneToolchain::Options.new(['--arch=arm64', "--install-dir=#{dir}"]) }
      assert_equal(true, Dir.exist?(dir))
    end

    # with --clean-install-dir and existing install dir
    dir = Dir.mktmpdir
    begin
      v = Crew::MakeStandaloneToolchain::Options.new(['--arch=arm64', "--install-dir=#{dir}", '--clean-install-dir'])
      assert_equal(dir,                v.install_dir)
      assert_equal(arch,               v.arch)
      assert_equal(def_gcc,            v.gcc)
      assert_equal(def_llvm,           v.llvm)
      assert_equal('gnustl',           v.stl)
      assert_equal(def_platform.name,  v.platform.name)
      assert_equal(arch.min_api_level, v.api_level)
      assert_equal([],                 v.with_packages)

      assert_equal(false, Dir.exist?(dir))
    ensure
      FileUtils.rm_rf dir
    end

    # unknown option
    assert_raises(UnknownOption) { Crew::MakeStandaloneToolchain::Options.new(['--unknown-option']) }
  end
end
