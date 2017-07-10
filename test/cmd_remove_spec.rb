# must be first file included
require_relative 'spec_helper.rb'

describe "crew remove" do
  before(:all) do
    ndk_init
  end

  before(:each) do
    clean_cache
    clean_hold
    repository_init
    repository_clone
  end

  context "without argument" do
    it "outputs error message" do
      crew 'remove'
      expect(exitstatus).to_not be_zero
      expect(err.split("\n")[0]).to eq('error: this command requires a formula argument')
    end
  end

  context "non existing name" do
    it "outputs error message" do
      crew 'remove', 'foo'
      expect(exitstatus).to_not be_zero
      expect(err.split("\n")[0]).to eq('error: no available formula for foo')
    end
  end

  context "one installed release with dependants" do
    it "outputs error message" do
      copy_formulas 'libone.rb', 'libtwo.rb'
      crew_checked 'install', 'libone:1.0.0'
      crew_checked 'install', 'libtwo:1.1.0'
      crew 'remove', 'libone'
      expect(exitstatus).to_not be_zero
      expect(err.split("\n")[0]).to eq('error: libone has installed dependants: target/libtwo')
      expect(pkg_cache_in?(:target, 'libone', '1.0.0', 1)).to eq(true)
      expect(pkg_cache_in?(:target, 'libtwo', '1.1.0', 1)).to eq(true)
    end
  end

  context "one of two installed releases with dependants" do
    it "outputs info about uninstalling the specified release" do
      copy_formulas 'libone.rb', 'libtwo.rb', 'libthree.rb'
      crew_checked 'install', 'libtwo:1.1.0'
      crew_checked 'install', 'libtwo:2.2.0'
      crew_checked 'install', 'libthree:2.2.2'
      crew 'remove', 'libtwo:1.1.0'
      expect(result).to eq(:ok)
      expect(out.chomp).to eq('removing libtwo:1.1.0')
      expect(pkg_cache_in?(:target, 'libone',   '1.0.0', 1)).to eq(true)
      expect(pkg_cache_in?(:target, 'libtwo',   '2.2.0', 1)).to eq(true)
      expect(pkg_cache_in?(:target, 'libthree', '2.2.2', 1)).to eq(true)
    end
  end

  context "one installed release without dependants" do
    it "outputs info about uninstalling release" do
      copy_formulas 'libone.rb'
      crew_checked 'install', 'libone:1.0.0'
      crew 'remove', 'libone'
      expect(result).to eq(:ok)
      expect(out).to eq("removing libone:1.0.0\n")
      expect(pkg_cache_in?(:target, 'libone', '1.0.0', 1)).to eq(true)
    end
  end

  context "all of the two installed releases without dependants" do
    it "outputs info about uninstalling releases" do
      copy_formulas 'libone.rb', 'libtwo.rb'
      crew_checked 'install', 'libone:1.0.0'
      crew_checked 'install', 'libtwo:1.1.0'
      crew_checked 'install', 'libtwo:2.2.0'
      crew 'remove', 'libtwo'
      expect(result).to eq(:ok)
      expect(out.split("\n")).to eq(["removing libtwo:1.1.0",
                                     "removing libtwo:2.2.0"])
      expect(pkg_cache_in?(:target, 'libone', '1.0.0', 1)).to eq(true)
      expect(pkg_cache_in?(:target, 'libtwo', '1.1.0', 1)).to eq(true)
      expect(pkg_cache_in?(:target, 'libtwo', '2.2.0', 1)).to eq(true)
    end
  end

  context "all installed releases with dependants" do
    it "outputs error message" do
      copy_formulas 'libone.rb', 'libtwo.rb', 'libthree.rb'
      crew_checked 'install', 'libone:1.0.0'
      crew_checked 'install', 'libtwo:1.1.0'
      crew_checked 'install', 'libtwo:2.2.0'
      crew_checked 'install', 'libthree:3.3.3'
      crew 'remove', 'libtwo'
      expect(exitstatus).to_not be_zero
      expect(err.split("\n")[0]).to eq('error: libtwo has installed dependants: target/libthree')
      expect(pkg_cache_in?(:target, 'libone',   '1.0.0', 1)).to eq(true)
      expect(pkg_cache_in?(:target, 'libtwo',   '1.1.0', 1)).to eq(true)
      expect(pkg_cache_in?(:target, 'libtwo',   '2.2.0', 1)).to eq(true)
      expect(pkg_cache_in?(:target, 'libthree', '3.3.3', 1)).to eq(true)
    end
  end

  context "try to remove utility" do
    it "outputs error message" do
      crew 'remove', 'curl'
      expect(exitstatus).to_not be_zero
      expect(err.split("\n")[0]).to eq("error: removing of 'curl' is not supported")
    end
  end
end
