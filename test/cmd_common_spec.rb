# must be first file included
require_relative 'spec_helper.rb'

require_relative '../library/global.rb'

describe "common code" do
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

  context "repository contains formula with depricated symbol in a filename" do
    it "list command fails with an error" do
      copy_package_formulas 'bad-file-name.rb'
      crew 'list'
      expect(exitstatus).to_not be_zero
      expect(err.split("\n")[0]).to match(/error: formula filename cannot contain symbol '-', use '_' instead/)
    end
  end

  context "repository contains two different formulas with the same name" do
    it "list command fails with an error" do
      copy_package_formulas 'libone.rb', 'libone_same_name.rb'
      crew 'list'
      expect(exitstatus).to_not be_zero
      expect(err.split("\n")[0]).to match(/error: bad name \'libone\' in .*: already defined in/)
    end
  end
end
