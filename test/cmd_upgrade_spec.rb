# must be first file included
require_relative 'spec_helper.rb'

require_relative '../library/global.rb'


describe "crew upgrade" do
  before(:all) do
    environment_init
    ndk_init
  end

  before(:each) do
    clean_cache
    clean_hold
    clean_utilities
    repository_init
    repository_clone
  end

  context "with argument" do
    it "outputs error message" do
      crew 'upgrade', 'baz'
      expect(exitstatus).to_not be_zero
      expect(err.split("\n")[0]).to eq('error: this command requires no arguments')
    end
  end

  context "when there are no formulas and no changes" do
    it "outputs nothing" do
      crew_checked 'update'
      crew '-b', 'upgrade'
      expect(result).to eq(:ok)
      expect(out).to eq('')
    end
  end

  context "when there are changes only in libraries" do

    context 'when there is one release with updated crystax_version' do
      it 'says about installing new release' do
        repository_add_formula :target, 'libone.rb'
        repository_clone
        crew_checked 'install', 'libone'
        repository_add_formula :target, 'libone-2.rb:libone.rb'
        crew_checked 'update'
        crew 'upgrade'
        expect(result).to eq(:ok)
        expect(out).to eq("Will install: libone:1.0.0_2\n"                                                                       \
                          "downloading #{Global::DOWNLOAD_BASE}/#{Global::NS_DIR[:target]}/libone-1.0.0_2.#{Global::ARCH_EXT}\n" \
                          "checking integrity of the archive file libone-1.0.0_2.#{Global::ARCH_EXT}\n"                          \
                          "unpacking archive\n")
      end
    end

    context "when there is one new release in one formula" do
      it "says and does nothing" do
        repository_add_formula :target, 'libone.rb', 'libtwo-1.rb:libtwo.rb'
        repository_clone
        crew_checked 'install', 'libone'
        crew_checked 'install', 'libtwo'
        repository_add_formula :target, 'libtwo.rb'
        crew_checked 'update'
        crew 'upgrade'
        expect(result).to eq(:ok)
        expect(out).to eq('')
      end
    end

    context "when there are two formulas with new release" do
      it "says and does nothing" do
        repository_add_formula :target, 'libone.rb', 'libtwo-1.rb:libtwo.rb', 'libthree-2.rb:libthree.rb'
        repository_clone
        crew_checked 'install', 'libone'
        crew_checked 'install', 'libtwo'
        crew_checked 'install', 'libthree:1.1.1'
        repository_add_formula :target, 'libtwo.rb', 'libthree.rb'
        crew_checked 'update'
        crew 'upgrade'
        expect(result).to eq(:ok)
        expect(out).to eq('')
      end
    end

    context "when there are two formulas with updated crystax versions" do
      it "says about installing new versions" do
        repository_add_formula :target, 'libone.rb', 'libtwo-1.rb:libtwo.rb', 'libthree-2.rb:libthree.rb'
        repository_clone
        crew_checked 'install', 'libone'
        crew_checked 'install', 'libtwo'
        crew_checked 'install', 'libthree:1.1.1'
        repository_add_formula :target, 'libtwo-1-cv-2.rb:libtwo.rb', 'libthree-2-cv-2.rb:libthree.rb'
        crew_checked 'update'
        crew 'upgrade'
        expect(result).to eq(:ok)
        expect(out.split("\n")).to eq(["Will install: libthree:1.1.1_2, libtwo:1.1.0_2",
                                       "downloading #{Global::DOWNLOAD_BASE}/#{Global::NS_DIR[:target]}/libthree-1.1.1_2.#{Global::ARCH_EXT}",
                                       "checking integrity of the archive file libthree-1.1.1_2.#{Global::ARCH_EXT}",
                                       "unpacking archive",
                                       "downloading #{Global::DOWNLOAD_BASE}/#{Global::NS_DIR[:target]}/libtwo-1.1.0_2.#{Global::ARCH_EXT}",
                                       "checking integrity of the archive file libtwo-1.1.0_2.#{Global::ARCH_EXT}",
                                       "unpacking archive"
                                      ])
      end
    end
  end

  context "when there are changes only in utilities" do

    context "when there is one new release for curl utility, with crystax_version changed" do
      it "says about installing new release" do
        repository_clone
        repository_add_formula :host, 'curl-2.rb:curl.rb'
        crew_checked 'update'
        crew '-b', 'upgrade'
        curl_rel = Crew::Test::UTILS_RELEASES['curl'][1]
        file = "curl-#{curl_rel}-#{Global::PLATFORM_NAME}.#{Global::ARCH_EXT}"
        expect(result).to eq(:ok)
        expect(out.split("\n")).to eq(["Will install: curl:#{curl_rel}",
                                       "downloading #{Global::DOWNLOAD_BASE}/#{Global::NS_DIR[:host]}/#{file}",
                                       "checking integrity of the archive file #{file}",
                                       "unpacking archive"
                                      ])
        expect(pkg_cache_in?(:host, 'curl', curl_rel.version, curl_rel.crystax_version)).to eq(true)
      end
    end

    context "when there are two new releases for curl utility, one with crystax_version changed, and one with upstream version changed" do
      it "says about installing new release (with new upstream version)" do
        repository_clone
        repository_add_formula :host, 'curl-3.rb:curl.rb'
        crew_checked 'update'
        crew '-b', 'upgrade'
        curl_rel = Crew::Test::UTILS_RELEASES['curl'][2]
        file = "curl-#{curl_rel}-#{Global::PLATFORM_NAME}.#{Global::ARCH_EXT}"
        expect(result).to eq(:ok)
        expect(out.split("\n")).to eq(["Will install: curl:#{curl_rel}",
                                       "downloading #{Global::DOWNLOAD_BASE}/#{Global::NS_DIR[:host]}/#{file}",
                                       "checking integrity of the archive file #{file}",
                                       "unpacking archive"
                                      ])
        expect(pkg_cache_in?(:host, 'curl', curl_rel.version, curl_rel.crystax_version)).to eq(true)
      end
    end

    context "when there are new releases for all utilities" do
      it "says about installing new releases" do
        repository_clone
        repository_add_formula :host, 'libarchive-2.rb:libarchive.rb', 'curl-3.rb:curl.rb', 'ruby-2.rb:ruby.rb'
        crew_checked 'update'
        # todo: remove -W
        crew '-W', '-b', 'upgrade'
        libarchive_new_rel = Crew::Test::UTILS_RELEASES['libarchive'][1]
        libarchive_file = "libarchive-#{libarchive_new_rel}-#{Global::PLATFORM_NAME}.#{Global::ARCH_EXT}"
        curl_new_rel = Crew::Test::UTILS_RELEASES['curl'][2]
        curl_file = "curl-#{curl_new_rel}-#{Global::PLATFORM_NAME}.#{Global::ARCH_EXT}"
        ruby_new_rel = Crew::Test::UTILS_RELEASES['ruby'][1]
        ruby_file = "ruby-#{ruby_new_rel}-#{Global::PLATFORM_NAME}.#{Global::ARCH_EXT}"
        expect(result).to eq(:ok)
        expect(out.split("\n")).to eq(["Will install: curl:#{curl_new_rel}, libarchive:#{libarchive_new_rel}, ruby:#{ruby_new_rel}",
                                       "downloading #{Global::DOWNLOAD_BASE}/#{Global::NS_DIR[:host]}/#{curl_file}",
                                       "checking integrity of the archive file #{curl_file}",
                                       "unpacking archive",
                                       "downloading #{Global::DOWNLOAD_BASE}/#{Global::NS_DIR[:host]}/#{libarchive_file}",
                                       "checking integrity of the archive file #{libarchive_file}",
                                       "unpacking archive",
                                       "downloading #{Global::DOWNLOAD_BASE}/#{Global::NS_DIR[:host]}/#{ruby_file}",
                                       "checking integrity of the archive file #{ruby_file}",
                                       "unpacking archive",
                                       "Start postponed upgrade process",
                                       "Finishing RUBY upgrade process",
                                       "= Removing old binary files",
                                       "= Removing old directories",
                                       "= Coping new files",
                                       "= Cleaning up"
                                      ])
        expect(pkg_cache_in?(:host, 'libarchive', libarchive_new_rel.version, libarchive_new_rel.crystax_version)).to eq(true)
        expect(pkg_cache_in?(:host, 'curl',       curl_new_rel.version,       curl_new_rel.crystax_version)).to       eq(true)
        expect(pkg_cache_in?(:host, 'ruby',       ruby_new_rel.version,       ruby_new_rel.crystax_version)).to       eq(true)
      end
    end
  end

  context "when there are changes in libraries and utilities" do

    context "when there is one package with updated crystax_version and one new release for curl utility" do
      it "says about installing new releases" do
        repository_add_formula :target, 'libone.rb', 'libtwo-1.rb:libtwo.rb'
        repository_clone
        crew_checked 'install', 'libone'
        crew_checked 'install', 'libtwo'
        repository_add_formula :target, 'libtwo-1-cv-2.rb:libtwo.rb'
        repository_add_formula :host, 'curl-2.rb:curl.rb'
        crew_checked 'update'
        crew 'upgrade'
        curl_new_rel = Crew::Test::UTILS_RELEASES['curl'][1]
        curl_file = "curl-#{curl_new_rel}-#{Global::PLATFORM_NAME}.#{Global::ARCH_EXT}"
        libtwo_ver = '1.1.0_2'
        libtwo_file = "libtwo-#{libtwo_ver}.#{Global::ARCH_EXT}"
        expect(result).to eq(:ok)
        expect(out.split("\n")).to eq(["Will install: curl:#{curl_new_rel}, libtwo:#{libtwo_ver}",
                                       "downloading #{Global::DOWNLOAD_BASE}/#{Global::NS_DIR[:host]}/#{curl_file}",
                                       "checking integrity of the archive file #{curl_file}",
                                       "unpacking archive",
                                       "downloading #{Global::DOWNLOAD_BASE}/#{Global::NS_DIR[:target]}/#{libtwo_file}",
                                       "checking integrity of the archive file #{libtwo_file}",
                                       "unpacking archive"
                                      ])
        expect(pkg_cache_in?(:host, 'curl', curl_new_rel.version, curl_new_rel.crystax_version)).to eq(true)
      end
    end

    context "when there are two formulas with new release in each and there are new releases for all utilities" do
      it "says about installing new releases" do
        repository_add_formula :target, 'libone.rb', 'libtwo-1.rb:libtwo.rb', 'libthree-2.rb:libthree.rb'
        repository_clone
        crew_checked 'install', 'libone'
        crew_checked 'install', 'libtwo'
        crew_checked 'install', 'libthree:1.1.1'
        repository_add_formula :target, 'libtwo-1-cv-2.rb:libtwo.rb', 'libthree-2-cv-2.rb:libthree.rb'
        repository_add_formula :host, 'curl-3.rb:curl.rb', 'libarchive-2.rb:libarchive.rb', 'ruby-2.rb:ruby.rb'
        crew_checked 'update'
        # todo: remove -W
        crew '-W', 'upgrade'
        lib3ver = '1.1.1_2'
        lib3file = "libthree-#{lib3ver}.#{Global::ARCH_EXT}"
        lib2ver = '1.1.0_2'
        lib2file = "libtwo-#{lib2ver}.#{Global::ARCH_EXT}"
        libarchive_new_rel = Crew::Test::UTILS_RELEASES['libarchive'][1]
        libarchive_old_rel = Crew::Test::UTILS_RELEASES['libarchive'][0]
        libarchive_file = "libarchive-#{libarchive_new_rel}-#{Global::PLATFORM_NAME}.#{Global::ARCH_EXT}"
        curl_new_rel = Crew::Test::UTILS_RELEASES['curl'][2]
        curl_file = "curl-#{curl_new_rel}-#{Global::PLATFORM_NAME}.#{Global::ARCH_EXT}"
        ruby_new_rel = Crew::Test::UTILS_RELEASES['ruby'][1]
        ruby_file = "ruby-#{ruby_new_rel}-#{Global::PLATFORM_NAME}.#{Global::ARCH_EXT}"
        expect(result).to eq(:ok)
        expect(out.split("\n")).to eq(["Will install: curl:#{curl_new_rel}, libarchive:#{libarchive_new_rel}, libthree:#{lib3ver}, libtwo:#{lib2ver}, ruby:#{ruby_new_rel}",
                                       "downloading #{Global::DOWNLOAD_BASE}/#{Global::NS_DIR[:host]}/#{curl_file}",
                                       "checking integrity of the archive file #{curl_file}",
                                       "unpacking archive",
                                       "downloading #{Global::DOWNLOAD_BASE}/#{Global::NS_DIR[:host]}/#{libarchive_file}",
                                       "checking integrity of the archive file #{libarchive_file}",
                                       "unpacking archive",
                                       "downloading #{Global::DOWNLOAD_BASE}/#{Global::NS_DIR[:target]}/#{lib3file}",
                                       "checking integrity of the archive file #{lib3file}",
                                       "unpacking archive",
                                       "downloading #{Global::DOWNLOAD_BASE}/#{Global::NS_DIR[:target]}/#{lib2file}",
                                       "checking integrity of the archive file #{lib2file}",
                                       "unpacking archive",
                                       "downloading #{Global::DOWNLOAD_BASE}/#{Global::NS_DIR[:host]}/#{ruby_file}",
                                       "checking integrity of the archive file #{ruby_file}",
                                       "unpacking archive",
                                       "Start postponed upgrade process",
                                       "Finishing RUBY upgrade process",
                                       "= Removing old binary files",
                                       "= Removing old directories",
                                       "= Coping new files",
                                       "= Cleaning up"
                                      ])
        expect(pkg_cache_in?(:host, 'libarchive', libarchive_new_rel.version, libarchive_new_rel.crystax_version)).to eq(true)
        expect(pkg_cache_in?(:host, 'curl',       curl_new_rel.version,       curl_new_rel.crystax_version)).to       eq(true)
        expect(pkg_cache_in?(:host, 'ruby',       ruby_new_rel.version,       ruby_new_rel.crystax_version)).to       eq(true)
      end
    end
  end
end
