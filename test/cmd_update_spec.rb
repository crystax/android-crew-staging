# must be first file included
require_relative 'spec_helper.rb'

require_relative '../library/global.rb'

describe "crew update" do
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

  context "with argument" do
    it "outputs error message" do
      crew 'update', 'baz'
      expect(exitstatus).to_not be_zero
      expect(err.split("\n")[0]).to eq('error: this command requires no arguments')
    end
  end

  context "when there are no formulas and no changes" do
    it "outputs nothing" do
      crew 'update'
      expect(result).to eq(:ok)
      expect(out).to eq("Already up-to-date.\n")
    end
  end

  context 'when crew script has been changed' do
    it 'says that crew scripts was updated' do
      repository_change_crew_script
      crew '-b', 'update'
      expect(result).to eq(:ok)
      #expect(out.strip).to eq('crew script has been updated')
      expect(out.strip).to match('Updated Crew from .*\.')
      expect(File.exist?("#{Crew::Test::CREW_DIR}/crew")).to eq(true)
    end
  end

  context "when there are changes only in libraries" do

    context "when there is one new formula" do
      it "says about one new formula" do
        repository_add_formula :target, 'libone.rb'
        crew '-b', 'update'
        expect(result).to eq(:ok)
        expect(out).to match("Updated Crew from .* to .*.\n" \
                             "==> New Formulae\n"            \
                             "libone\n")
      end
    end

    context "when there is one modified formula and one new formula" do
      it "says about one modified and one new formula" do
        repository_add_formula :target, 'libone.rb', 'libtwo-1.rb:libtwo.rb'
        repository_clone
        repository_add_formula :target, 'libtwo.rb', 'libfour.rb'
        crew 'update'
        expect(result).to eq(:ok)
        expect(out).to match("Updated Crew from .* to .*.\n" \
                             "==> New Formulae\n"            \
                             "libfour\n"                     \
                             "==> Updated Formulae\n"        \
                             "libtwo\n")
      end
    end

    context "when there is one modified formula, one new formula and one deleted formula" do
      it "says about one modified and one new formula" do
        repository_add_formula :target, 'libone.rb', 'libtwo-1.rb:libtwo.rb', 'libthree.rb'
        repository_clone
        repository_add_formula :target, 'libtwo.rb', 'libfour.rb'
        repository_del_formula :target, 'libthree.rb'
        crew 'update'
        expect(result).to eq(:ok)
        expect(out).to match("Updated Crew from .* to .*.\n" \
                             "==> New Formulae\n"            \
                             "libfour\n"                     \
                             "==> Updated Formulae\n"        \
                             "libtwo\n"                      \
                             "==> Deleted Formulae\n"        \
                             "libthree\n")
      end
    end
  end

  context "when there are changes only in utilities" do

    context "when there is one updated utility" do
      it "says about updated utility" do
        repository_add_formula :host, 'curl-2.rb:curl.rb'
        crew 'update'
        expect(result).to eq(:ok)
        expect(out).to match("Updated Crew from .* to .*.\n" \
                             "==> Updated Utilities\n"       \
                             "curl\n")
      end
    end

    context "when there are two updated utilities" do
      it "says about updated utilities" do
        repository_add_formula :host, 'curl-2.rb:curl.rb', 'ruby-2.rb:ruby.rb'
        crew 'update'
        expect(result).to eq(:ok)
        expect(out).to match("Updated Crew from .* to .*.\n" \
                             "==> Updated Utilities\n"       \
                             "curl, ruby\n")
      end
    end

    context "when there are four updated utilities" do
      it "says about updated utilities" do
        repository_add_formula :host, 'curl-2.rb:curl.rb', 'libarchive-2.rb:libarchive.rb', 'ruby-2.rb:ruby.rb'
        crew 'update'
        expect(result).to eq(:ok)
        expect(out).to match("Updated Crew from .* to .*.\n" \
                             "==> Updated Utilities\n"       \
                             "curl, libarchive, ruby\n")
      end
    end
  end

  context "where there are changes in libraries and utilities" do

    context "when there is one modified formula, one new formula, one deleted formula, and three updated utilities" do
      it "ouputs info about all changes" do
        repository_add_formula :target, 'libone.rb', 'libtwo-1.rb:libtwo.rb', 'libthree.rb'
        repository_clone
        repository_add_formula :target, 'libtwo.rb', 'libfour.rb'
        repository_del_formula :target, 'libthree.rb'
        repository_add_formula :host, 'curl-2.rb:curl.rb', 'ruby-2.rb:ruby.rb'
        crew 'update'
        expect(result).to eq(:ok)
        expect(out).to match("Updated Crew from .* to .*.\n" \
                             "==> Updated Utilities\n"       \
                             "curl, ruby\n"                  \
                             "==> New Formulae\n"            \
                             "libfour\n"                     \
                             "==> Updated Formulae\n"        \
                             "libtwo\n"                      \
                             "==> Deleted Formulae\n"        \
                             "libthree\n")
      end
    end
  end
end
