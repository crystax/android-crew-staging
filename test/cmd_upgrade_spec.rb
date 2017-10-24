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

    context "when there is one new release in one formula" do
      it "says about installing new release" do
        repository_add_formula :target, 'libone.rb', 'libtwo-1.rb:libtwo.rb'
        repository_clone
        crew_checked 'install', 'libone'
        crew_checked 'install', 'libtwo'
        repository_add_formula :target, 'libtwo.rb'
        crew_checked 'update'
        crew 'upgrade'
        expect(result).to eq(:ok)
        expect(out).to eq("Will install: libtwo:2.2.0:1\n"                                                            \
                          "downloading #{Global::DOWNLOAD_BASE}/#{Global::NS_DIR[:target]}/libtwo-2.2.0_1.#{Global::ARCH_EXT}\n" \
                          "checking integrity of the archive file libtwo-2.2.0_1.#{Global::ARCH_EXT}\n"               \
                          "unpacking archive\n")
      end
    end

    context "when there are two formulas with new release in each" do
      it "says about installing new releases" do
        repository_add_formula :target, 'libone.rb', 'libtwo-1.rb:libtwo.rb', 'libthree-2.rb:libthree.rb'
        repository_clone
        crew_checked 'install', 'libone'
        crew_checked 'install', 'libtwo'
        crew_checked 'install', 'libthree:1.1.1'
        repository_add_formula :target, 'libtwo.rb', 'libthree.rb'
        crew_checked 'update'
        crew 'upgrade'
        expect(result).to eq(:ok)
        expect(out).to eq("Will install: libthree:3.3.3:1, libtwo:2.2.0:1\n"                             \
                          "downloading #{Global::DOWNLOAD_BASE}/#{Global::NS_DIR[:target]}/libthree-3.3.3_1.#{Global::ARCH_EXT}\n" \
                          "checking integrity of the archive file libthree-3.3.3_1.#{Global::ARCH_EXT}\n"                 \
                          "unpacking archive\n"                                                          \
                          "downloading #{Global::DOWNLOAD_BASE}/#{Global::NS_DIR[:target]}/libtwo-2.2.0_1.#{Global::ARCH_EXT}\n"     \
                          "checking integrity of the archive file libtwo-2.2.0_1.#{Global::ARCH_EXT}\n"                   \
                          "unpacking archive\n")
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
        ver = Crew::Test::UTILS_RELEASES['curl'][1].version
        cxver = Crew::Test::UTILS_RELEASES['curl'][1].crystax_version
        file = "curl-#{ver}_#{cxver}-#{Global::PLATFORM_NAME}.#{Global::ARCH_EXT}"
        expect(result).to eq(:ok)
        expect(out).to eq("Will install: curl:#{ver}:#{cxver}\n"                      \
                          "downloading #{Global::DOWNLOAD_BASE}/#{Global::NS_DIR[:host]}/#{file}\n" \
                          "checking integrity of the archive file #{file}\n"          \
                          "unpacking archive\n")
        expect(pkg_cache_in?(:host, 'curl', ver, cxver)).to eq(true)
      end
    end

    context "when there are two new releases for curl utility, one with crystax_version changed, and one with upstream version changed" do
      it "says about installing new release (with new upstream)" do
        repository_clone
        repository_add_formula :host, 'curl-3.rb:curl.rb'
        crew_checked 'update'
        crew '-b', 'upgrade'
        old_rel = Crew::Test::UTILS_RELEASES['curl'][0].to_s
        ver = Crew::Test::UTILS_RELEASES['curl'][2].version
        cxver = Crew::Test::UTILS_RELEASES['curl'][2].crystax_version
        file = "curl-#{ver}_#{cxver}-#{Global::PLATFORM_NAME}.#{Global::ARCH_EXT}"
        expect(result).to eq(:ok)
        expect(out).to eq("Will install: curl:#{ver}:#{cxver}\n"                          \
                          "downloading #{Global::DOWNLOAD_BASE}/#{Global::NS_DIR[:host]}/#{file}\n" \
                          "checking integrity of the archive file #{file}\n"              \
                          "unpacking archive\n")
        expect(pkg_cache_in?(:host, 'curl', ver, cxver)).to eq(true)
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
        libarchive_old_rel = Crew::Test::UTILS_RELEASES['libarchive'][0]
        libarchive_file = "libarchive-#{libarchive_new_rel}-#{Global::PLATFORM_NAME}.#{Global::ARCH_EXT}"
        libarchive_ver = "#{libarchive_new_rel.version}:#{libarchive_new_rel.crystax_version}"
        curl_new_rel = Crew::Test::UTILS_RELEASES['curl'][2]
        curl_old_rel = Crew::Test::UTILS_RELEASES['curl'][0]
        curl_file = "curl-#{curl_new_rel}-#{Global::PLATFORM_NAME}.#{Global::ARCH_EXT}"
        curl_ver = "#{curl_new_rel.version}:#{curl_new_rel.crystax_version}"
        ruby_new_rel = Crew::Test::UTILS_RELEASES['ruby'][1]
        ruby_old_rel = Crew::Test::UTILS_RELEASES['ruby'][0]
        ruby_file = "ruby-#{ruby_new_rel}-#{Global::PLATFORM_NAME}.#{Global::ARCH_EXT}"
        ruby_ver = "#{ruby_new_rel.version}:#{ruby_new_rel.crystax_version}"
        expect(result).to eq(:ok)
        expect(out).to eq("Will install: bsdtar:#{libarchive_ver}, curl:#{curl_ver}, ruby:#{ruby_ver}\n"   \
                          "downloading #{Global::DOWNLOAD_BASE}/#{Global::NS_DIR[:host]}/#{libarchive_file}\n" \
                          "checking integrity of the archive file #{libarchive_file}\n"                    \
                          "unpacking archive\n"                                                            \
                          "downloading #{Global::DOWNLOAD_BASE}/#{Global::NS_DIR[:host]}/#{curl_file}\n"             \
                          "checking integrity of the archive file #{curl_file}\n"                          \
                          "unpacking archive\n"                                                            \
                          "downloading #{Global::DOWNLOAD_BASE}/#{Global::NS_DIR[:host]}/#{ruby_file}\n"             \
                          "checking integrity of the archive file #{ruby_file}\n"                          \
                          "unpacking archive\n")
        expect(pkg_cache_in?(:host, 'libarchive', libarchive_new_rel.version,  libarchive_new_rel.crystax_version)).to eq(true)
        expect(pkg_cache_in?(:host, 'curl',       curl_new_rel.version,        curl_new_rel.crystax_version)).to       eq(true)
        expect(pkg_cache_in?(:host, 'ruby',       ruby_new_rel.version,        ruby_new_rel.crystax_version)).to       eq(true)
      end
    end
  end

  context "when there are changes in libraries and utilities" do

    context "when there is one new release in one formula and one new release for curl utility" do
      it "says about installing new releases" do
        repository_add_formula :target, 'libone.rb', 'libtwo-1.rb:libtwo.rb'
        repository_clone
        crew_checked 'install', 'libone'
        crew_checked 'install', 'libtwo'
        repository_add_formula :target, 'libtwo.rb'
        repository_add_formula :host, 'curl-2.rb:curl.rb'
        crew_checked 'update'
        crew 'upgrade'
        curl_new_rel = Crew::Test::UTILS_RELEASES['curl'][1]
        curl_old_rel = Crew::Test::UTILS_RELEASES['curl'][0]
        curl_ver = "#{curl_new_rel.version}:#{curl_new_rel.crystax_version}"
        curl_file = "curl-#{curl_new_rel}-#{Global::PLATFORM_NAME}.#{Global::ARCH_EXT}"
        libtwo_file = "libtwo-2.2.0_1.#{Global::ARCH_EXT}"
        expect(result).to eq(:ok)
        expect(out.split("\n")).to eq(["Will install: curl:#{curl_ver}, libtwo:2.2.0:1",
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
        repository_add_formula :target, 'libtwo.rb', 'libthree.rb'
        repository_add_formula :host, 'curl-3.rb:curl.rb', 'libarchive-2.rb:libarchive.rb', 'ruby-2.rb:ruby.rb'
        crew_checked 'update'
        # todo: remove -W
        crew '-W', 'upgrade'
        lib3file = "libthree-3.3.3_1.#{Global::ARCH_EXT}"
        lib2file = "libtwo-2.2.0_1.#{Global::ARCH_EXT}"
        libarchive_new_rel = Crew::Test::UTILS_RELEASES['libarchive'][1]
        libarchive_old_rel = Crew::Test::UTILS_RELEASES['libarchive'][0]
        libarchive_file = "libarchive-#{libarchive_new_rel}-#{Global::PLATFORM_NAME}.#{Global::ARCH_EXT}"
        libarchive_ver = "#{libarchive_new_rel.version}:#{libarchive_new_rel.crystax_version}"
        curl_new_rel = Crew::Test::UTILS_RELEASES['curl'][2]
        curl_old_rel = Crew::Test::UTILS_RELEASES['curl'][0]
        curl_file = "curl-#{curl_new_rel}-#{Global::PLATFORM_NAME}.#{Global::ARCH_EXT}"
        curl_ver = "#{curl_new_rel.version}:#{curl_new_rel.crystax_version}"
        ruby_new_rel = Crew::Test::UTILS_RELEASES['ruby'][1]
        ruby_old_rel = Crew::Test::UTILS_RELEASES['ruby'][0]
        ruby_file = "ruby-#{ruby_new_rel}-#{Global::PLATFORM_NAME}.#{Global::ARCH_EXT}"
        ruby_ver = "#{ruby_new_rel.version}:#{ruby_new_rel.crystax_version}"
        expect(result).to eq(:ok)
        expect(out.split("\n")).to eq(["Will install: bsdtar:#{libarchive_ver}, curl:#{curl_ver}, libthree:3.3.3:1, libtwo:2.2.0:1, ruby:#{ruby_ver}",
                                       "downloading #{Global::DOWNLOAD_BASE}/#{Global::NS_DIR[:host]}/#{libarchive_file}",
                                       "checking integrity of the archive file #{libarchive_file}",
                                       "unpacking archive",
                                       "downloading #{Global::DOWNLOAD_BASE}/#{Global::NS_DIR[:host]}/#{curl_file}",
                                       "checking integrity of the archive file #{curl_file}",
                                       "unpacking archive",
                                       "downloading #{Global::DOWNLOAD_BASE}/#{Global::NS_DIR[:target]}/#{lib3file}",
                                       "checking integrity of the archive file #{lib3file}",
                                       "unpacking archive",
                                       "downloading #{Global::DOWNLOAD_BASE}/#{Global::NS_DIR[:target]}/#{lib2file}",
                                       "checking integrity of the archive file #{lib2file}",
                                       "unpacking archive",
                                       "downloading #{Global::DOWNLOAD_BASE}/#{Global::NS_DIR[:host]}/#{ruby_file}",
                                       "checking integrity of the archive file #{ruby_file}",
                                       "unpacking archive"
                                      ])
        expect(pkg_cache_in?(:host, 'libarchive', libarchive_new_rel.version,  libarchive_new_rel.crystax_version)).to eq(true)
        expect(pkg_cache_in?(:host, 'curl',       curl_new_rel.version,        curl_new_rel.crystax_version)).to       eq(true)
        expect(pkg_cache_in?(:host, 'ruby',       ruby_new_rel.version,        ruby_new_rel.crystax_version)).to       eq(true)
      end
    end
  end
end
