# must be first file included
require_relative 'spec_helper.rb'

describe "crew remove" do
  before(:all) do
    environment_init
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
      libone_rel = pkg_cache_add_package_with_formula('libone')
      libtwo_rel = pkg_cache_add_package_with_formula('libtwo', update: true, release: Release.new('1.1.0', 1))
      crew_checked 'install', 'libone:1.0.0', 'libtwo:1.1.0'
      crew 'remove', 'libone'
      expect(exitstatus).to_not be_zero
      expect(err.split("\n")[0]).to eq('error: libone has installed dependants: target/libtwo')
      expect(pkg_cache_has_package?('libone', libone_rel)).to eq(true)
      expect(pkg_cache_has_package?('libtwo', libtwo_rel)).to eq(true)
    end
  end

  context "one of two installed releases with dependants" do
    it "outputs info about uninstalling the specified release" do
      libone_rel   = pkg_cache_add_package_with_formula('libone')
      libtwo_rel_1 = pkg_cache_add_package_with_formula('libtwo',   update: true, release: Release.new('1.1.0', 1))
      libtwo_rel_2 = pkg_cache_add_package_with_formula('libtwo',   update: true, release: Release.new('2.2.0', 1))
      libthree_rel = pkg_cache_add_package_with_formula('libthree', update: true, release: Release.new('2.2.2', 1))
      crew_checked 'install', 'libtwo:1.1.0', 'libtwo:2.2.0', 'libthree:2.2.2'
      crew 'remove', 'libtwo:1.1.0'
      expect(result).to eq(:ok)
      expect(out.chomp).to eq("removing libtwo:#{libtwo_rel_1.version}")
      expect(pkg_cache_has_package?('libone',   libone_rel)).to   eq(true)
      expect(pkg_cache_has_package?('libtwo',   libtwo_rel_2)).to eq(true)
      expect(pkg_cache_has_package?('libthree', libthree_rel)).to eq(true)
    end
  end

  context "one installed release without dependants" do
    it "outputs info about uninstalling release" do
      rel = pkg_cache_add_package_with_formula('libone')
      crew_checked 'install', 'libone'
      crew 'remove', 'libone'
      expect(result).to eq(:ok)
      expect(out).to eq("removing libone:#{rel.version}\n")
      expect(pkg_cache_has_package?('libone', rel)).to eq(true)
    end
  end

  context "all of the two installed releases without dependants" do
    it "outputs info about uninstalling releases" do
      libone_rel   = pkg_cache_add_package_with_formula('libone')
      libtwo_rel_1 = pkg_cache_add_package_with_formula('libtwo', update: true, release: Release.new('1.1.0', 1))
      libtwo_rel_2 = pkg_cache_add_package_with_formula('libtwo', update: true, release: Release.new('2.2.0', 1))
      crew_checked 'install', 'libone', 'libtwo:1.1.0', 'libtwo:2.2.0'
      crew 'remove', 'libtwo'
      expect(result).to eq(:ok)
      expect(out.split("\n")).to eq(["removing libtwo:#{libtwo_rel_1.version}",
                                     "removing libtwo:#{libtwo_rel_2.version}"])
      expect(pkg_cache_has_package?('libone', libone_rel)).to   eq(true)
      expect(pkg_cache_has_package?('libtwo', libtwo_rel_1)).to eq(true)
      expect(pkg_cache_has_package?('libtwo', libtwo_rel_2)).to eq(true)
    end
  end

  context "all installed releases with dependants" do
    it "outputs error message" do
      libone_rel   = pkg_cache_add_package_with_formula('libone')
      libtwo_rel_1 = pkg_cache_add_package_with_formula('libtwo', update: true, release: Release.new('1.1.0', 1))
      libtwo_rel_2 = pkg_cache_add_package_with_formula('libtwo', update: true, release: Release.new('2.2.0', 1))
      libthree_rel = pkg_cache_add_package_with_formula('libthree')
      crew_checked 'install', 'libone', 'libtwo:1.1.0', 'libtwo:2.2.0', 'libthree'
      crew 'remove', 'libtwo'
      expect(exitstatus).to_not be_zero
      expect(err.split("\n")[0]).to eq('error: libtwo has installed dependants: target/libthree')
      expect(pkg_cache_has_package?('libone',   libone_rel)).to   eq(true)
      expect(pkg_cache_has_package?('libtwo',   libtwo_rel_1)).to eq(true)
      expect(pkg_cache_has_package?('libtwo',   libtwo_rel_2)).to eq(true)
      expect(pkg_cache_has_package?('libthree', libthree_rel)).to eq(true)
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
