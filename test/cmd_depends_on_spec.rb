# must be first file included
require_relative 'spec_helper.rb'

require_relative '../library/global.rb'

describe "crew depends-on" do
  before(:all) do
    environment_init
    ndk_init
  end

  before(:each) do
    clean_hold
    clean_cache
    repository_init
    repository_clone
  end

  context 'no arguments' do
    it 'depends-on command outputs error message' do
      crew 'depends-on'
      expect(exitstatus).to_not be_zero
      expect(err.strip).to match(/error: .*/)
    end
  end

  context 'more than one argument' do
    it 'depends-on command outputs error message' do
      crew 'depends-on', 'libone', 'libtwo'
      expect(exitstatus).to_not be_zero
      expect(err.strip).to match(/error: .*/)
    end
  end

  context "repository contains package formula with no dependencies" do
    it "depends-on command outputs nothing" do
      copy_package_formulas 'libone.rb'
      crew 'depends-on', 'libone'
      expect(exitstatus).to be_zero
      expect(out.strip).to eq('')
    end
  end

  context "repository contains package two formulas, one depends on another" do

    before do
      copy_package_formulas 'libone.rb', 'libtwo.rb'
    end

    context 'check formula that has no dependant formulas' do
      it "depends-on command outputs nothing" do
        crew 'depends-on', 'libtwo'
        expect(exitstatus).to be_zero
        expect(out.strip).to eq('')
      end
    end

    context 'check formula that has dependant formulas' do
      it "depends-on command outputs dependency fully qualified name" do
        crew 'depends-on', 'libone'
        expect(exitstatus).to be_zero
        expect(out.strip).to eq('target/libtwo')
      end
    end
  end
end
