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
      repository_clone
      crew_checked 'update'
      crew '-b', 'upgrade'
      expect(result).to eq(:ok)
      expect(out).to eq('')
    end
  end

  context "when there are changes only in target packages" do

    context 'and there is a package with one release' do

      before do
        repository_add_formula :target, 'libone.rb'
        repository_clone
      end

      context 'and that package is not installed' do

        context 'and it has an updated crystax version' do
          it 'says and does nothing' do
            repository_add_formula :target, 'libone-1.0.0_2.rb:libone.rb'
            crew_checked 'update'
            crew 'upgrade'
            expect(result).to eq(:ok)
            expect(out).to eq('')
          end
        end

        context 'and it has a new release' do
          it 'says and does nothing' do
            repository_add_formula :target, 'libone-2.0.0_1.rb:libone.rb'
            crew_checked 'update'
            crew 'upgrade'
            expect(result).to eq(:ok)
            expect(out).to eq('')
          end
        end
      end

      context 'and that package is installed' do

        before do
          crew_checked 'install', 'libone'
        end

        context 'and it has an updated crystax version' do
          it 'installs a release with updated crystax version' do
            repository_add_formula :target, 'libone-1.0.0_2.rb:libone.rb'
            crew_checked 'update'
            crew 'upgrade'
            expect(result).to eq(:ok)
            expect(out.split("\n")).to eq(["Will install: libone:1.0.0_2",
                                           "downloading #{Global::DOWNLOAD_BASE}/#{Global::NS_DIR[:target]}/libone-1.0.0_2.#{Global::ARCH_EXT}",
                                           "checking integrity of the archive file libone-1.0.0_2.#{Global::ARCH_EXT}",
                                           "unpacking archive"
                                          ])
          end
        end

        context 'and it has a new release' do
          it 'says and does nothing' do
            repository_add_formula :target, 'libone-2.0.0_1.rb:libone.rb'
            crew_checked 'update'
            crew 'upgrade'
            expect(result).to eq(:ok)
            expect(out).to eq('')
          end
        end
      end
    end

    context 'and there is a package with two releases' do

      before do
        repository_add_formula :target, 'libone.rb', 'libtwo.rb'
        repository_clone
        crew_checked 'install', 'libone'
      end

      context 'and no releases are installed' do

        context 'and one release has an updated crystax version' do
          it 'says and does nothing' do
            repository_add_formula :target, 'libtwo-1.1.0_2.rb:libtwo.rb'
            crew_checked 'update'
            crew 'upgrade'
            expect(result).to eq(:ok)
            expect(out).to eq('')
          end
        end

        context 'and both releases has an updated crystax version' do
          it 'says and does nothing' do
            repository_add_formula :target, 'libtwo-2.rb:libtwo.rb'
            crew_checked 'update'
            crew 'upgrade'
            expect(result).to eq(:ok)
            expect(out).to eq('')
          end
        end
      end

      context 'and one release is installed' do

        before do
          crew_checked 'install', 'libtwo:1.1.0'
        end

        context 'and installed release has an updated crystax version' do
          it 'installs a release with updated crystax version' do
            repository_add_formula :target, 'libtwo-1.1.0_2.rb:libtwo.rb'
            crew_checked 'update'
            crew 'upgrade'
            expect(result).to eq(:ok)
            expect(out.split("\n")).to eq(["Will install: libtwo:1.1.0_2",
                                           "downloading #{Global::DOWNLOAD_BASE}/#{Global::NS_DIR[:target]}/libtwo-1.1.0_2.#{Global::ARCH_EXT}",
                                           "checking integrity of the archive file libtwo-1.1.0_2.#{Global::ARCH_EXT}",
                                           "unpacking archive"
                                          ])
          end
        end

        context 'and not installed release has an updated crystax version' do
          it 'says and does nothing' do
            repository_add_formula :target, 'libtwo-2.2.0_2.rb:libtwo.rb'
            crew_checked 'update'
            crew 'upgrade'
            expect(result).to eq(:ok)
            expect(out).to eq('')
          end
        end
      end

      context 'and both releases are installed' do

        before do
          crew_checked 'install', '--all-versions', 'libtwo'
        end

        context 'and one release has an updated crystax version' do
          it 'installs a release with updated crystax version' do
            repository_add_formula :target, 'libtwo-1.1.0_2.rb:libtwo.rb'
            crew_checked 'update'
            crew 'upgrade'
            expect(result).to eq(:ok)
            expect(out.split("\n")).to eq(["Will install: libtwo:1.1.0_2",
                                           "downloading #{Global::DOWNLOAD_BASE}/#{Global::NS_DIR[:target]}/libtwo-1.1.0_2.#{Global::ARCH_EXT}",
                                           "checking integrity of the archive file libtwo-1.1.0_2.#{Global::ARCH_EXT}",
                                           "unpacking archive"
                                          ])
          end
        end

        context 'and both releases has an updated crystax version' do
          it 'installs both releases' do
            repository_add_formula :target, 'libtwo-2.rb:libtwo.rb'
            crew_checked 'update'
            crew 'upgrade'
            expect(result).to eq(:ok)
            expect(out.split("\n")).to eq(["Will install: libtwo:1.1.0_2, libtwo:2.2.0_2",
                                           "downloading #{Global::DOWNLOAD_BASE}/#{Global::NS_DIR[:target]}/libtwo-1.1.0_2.#{Global::ARCH_EXT}",
                                           "checking integrity of the archive file libtwo-1.1.0_2.#{Global::ARCH_EXT}",
                                           "unpacking archive",
                                           "downloading #{Global::DOWNLOAD_BASE}/#{Global::NS_DIR[:target]}/libtwo-2.2.0_2.#{Global::ARCH_EXT}",
                                           "checking integrity of the archive file libtwo-2.2.0_2.#{Global::ARCH_EXT}",
                                           "unpacking archive"
                                          ])
          end
        end
      end
    end

    context 'when there is a package with 3 releases' do

      context 'when one release is installed and it has an updated crystax version' do
        it "installs release with updated crystax version" do
          repository_add_formula :target, 'libone.rb', 'libtwo.rb', 'libthree-2.rb:libthree.rb'
          repository_clone
          crew_checked 'install', 'libone'
          crew_checked 'install', 'libtwo'
          crew_checked 'install', 'libthree:1.1.1'
          repository_add_formula :target, 'libthree-2-cv-2.rb:libthree.rb'
          crew_checked 'update'
          crew 'upgrade'
          expect(result).to eq(:ok)
          expect(out.split("\n")).to eq(["Will install: libthree:1.1.1_2",
                                         "downloading #{Global::DOWNLOAD_BASE}/#{Global::NS_DIR[:target]}/libthree-1.1.1_2.#{Global::ARCH_EXT}",
                                         "checking integrity of the archive file libthree-1.1.1_2.#{Global::ARCH_EXT}",
                                         "unpacking archive"
                                        ])
        end
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

    context "when there is one release with updated crystax version" do
      it "installs package with updated crystax version" do
        repository_add_formula :target, 'libone.rb'
        repository_clone
        crew_checked 'install', 'libone'
        repository_add_formula :target, 'libone-1.0.0_2.rb:libone.rb'
        crew_checked 'update'
        crew 'upgrade'
        expect(result).to eq(:ok)
        expect(out.split("\n")).to eq(["Will install: libone:1.0.0_2",
                                       "downloading http://localhost:9999/packages/libone-1.0.0_2.tar.xz",
                                       "checking integrity of the archive file libone-1.0.0_2.tar.xz",
                                       "unpacking archive"
                                      ])
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

    context 'when there are changes only in multi-version base target packages (like libstdc++ and libc++)' do

      before do
        FileUtils.rm_rf "#{Global::SERVICE_DIR}/test_base_package"
        repository_add_formula :target, 'test_base_package.rb'
        repository_clone
      end

      context 'when no releases are installed' do

        context 'when one release has an updated crystax version' do
          it 'says and does nothing' do
            repository_add_formula :target, 'test_base_package-1.rb:test_base_package.rb'
            crew_checked 'update'
            crew 'upgrade'
            expect(result).to eq(:ok)
            expect(out).to eq('')
          end
        end

        context 'when two releases has an updated crystax version' do
          it 'says and does nothing' do
            repository_add_formula :target, 'test_base_package-2.rb:test_base_package.rb'
            crew_checked 'update'
            crew 'upgrade'
            expect(result).to eq(:ok)
            expect(out).to eq('')
          end
        end

        context 'when all releases has an updated crystax version' do
          it 'says and does nothing' do
            repository_add_formula :target, 'test_base_package-3.rb:test_base_package.rb'
            crew_checked 'update'
            crew 'upgrade'
            expect(result).to eq(:ok)
            expect(out).to eq('')
          end
        end

        context 'when new release available' do
          it 'says and does nothing' do
            repository_add_formula :target, 'test_base_package-4.rb:test_base_package.rb'
            crew_checked 'update'
            crew 'upgrade'
            expect(result).to eq(:ok)
            expect(out).to eq('')
          end
        end
      end

      context 'when one release is installed' do

        before do
          crew_checked 'install', 'test_base_package:2'
        end

        context 'when installed release has an updated crystax version' do
          it 'installs a release with updated crystax version' do
            repository_add_formula :target, 'test_base_package-1.rb:test_base_package.rb'
            crew_checked 'update'
            crew 'upgrade'
            expect(result).to eq(:ok)
            expect(out.split("\n")).to eq(["Will install: test_base_package:2_2",
                                           "downloading #{Global::DOWNLOAD_BASE}/#{Global::NS_DIR[:target]}/test_base_package-2_2.#{Global::ARCH_EXT}",
                                           "checking integrity of the archive file test_base_package-2_2.#{Global::ARCH_EXT}",
                                           "unpacking archive"
                                          ])
          end
        end

        context 'when two releases (one installed and one not installed) has an updated crystax version' do
          it 'installs a release with updated crystax version which was already installed' do
            repository_add_formula :target, 'test_base_package-2.rb:test_base_package.rb'
            crew_checked 'update'
            crew 'upgrade'
            expect(result).to eq(:ok)
            expect(out.split("\n")).to eq(["Will install: test_base_package:2_2",
                                           "downloading #{Global::DOWNLOAD_BASE}/#{Global::NS_DIR[:target]}/test_base_package-2_2.#{Global::ARCH_EXT}",
                                           "checking integrity of the archive file test_base_package-2_2.#{Global::ARCH_EXT}",
                                           "unpacking archive"
                                          ])
          end
        end

        context 'when all releases has an updated crystax version' do
          it 'installs a release with updated crystax version which was already installed' do
            repository_add_formula :target, 'test_base_package-3.rb:test_base_package.rb'
            crew_checked 'update'
            crew 'upgrade'
            expect(result).to eq(:ok)
            expect(out.split("\n")).to eq(["Will install: test_base_package:2_2",
                                           "downloading #{Global::DOWNLOAD_BASE}/#{Global::NS_DIR[:target]}/test_base_package-2_2.#{Global::ARCH_EXT}",
                                           "checking integrity of the archive file test_base_package-2_2.#{Global::ARCH_EXT}",
                                           "unpacking archive"
                                          ])
          end
        end

        context 'when new release available' do
          it 'says and does nothing' do
            repository_add_formula :target, 'test_base_package-4.rb:test_base_package.rb'
            crew_checked 'update'
            crew 'upgrade'
            expect(result).to eq(:ok)
            expect(out).to eq('')
          end
        end
      end

      context 'when two releases are installed' do

        before do
          crew_checked 'install', 'test_base_package:1', 'test_base_package:2'
        end

        context 'when one of installed releases has an updated crystax version' do
          it 'installs a release with updated crystax version' do
            repository_add_formula :target, 'test_base_package-1.rb:test_base_package.rb'
            crew_checked 'update'
            crew 'upgrade'
            expect(result).to eq(:ok)
            expect(out.split("\n")).to eq(["Will install: test_base_package:2_2",
                                           "downloading #{Global::DOWNLOAD_BASE}/#{Global::NS_DIR[:target]}/test_base_package-2_2.#{Global::ARCH_EXT}",
                                           "checking integrity of the archive file test_base_package-2_2.#{Global::ARCH_EXT}",
                                           "unpacking archive"
                                          ])
          end
        end

        context 'when two releases (one installed and one not installed) has an updated crystax version' do
          it 'installs a release with updated crystax version that was already installed' do
            repository_add_formula :target, 'test_base_package-2-3.rb:test_base_package.rb'
            crew_checked 'update'
            crew 'upgrade'
            expect(result).to eq(:ok)
            expect(out.split("\n")).to eq(["Will install: test_base_package:2_2",
                                           "downloading #{Global::DOWNLOAD_BASE}/#{Global::NS_DIR[:target]}/test_base_package-2_2.#{Global::ARCH_EXT}",
                                           "checking integrity of the archive file test_base_package-2_2.#{Global::ARCH_EXT}",
                                           "unpacking archive"
                                          ])
          end
        end

        context 'when two releases (both installed) has an updated crystax version' do
          it 'installs updates for both installed releases' do
            repository_add_formula :target, 'test_base_package-2.rb:test_base_package.rb'
            crew_checked 'update'
            crew 'upgrade'
            expect(result).to eq(:ok)
            expect(out.split("\n")).to eq(["Will install: test_base_package:1_2, test_base_package:2_2",
                                           "downloading #{Global::DOWNLOAD_BASE}/#{Global::NS_DIR[:target]}/test_base_package-1_2.#{Global::ARCH_EXT}",
                                           "checking integrity of the archive file test_base_package-1_2.#{Global::ARCH_EXT}",
                                           "unpacking archive",
                                           "downloading #{Global::DOWNLOAD_BASE}/#{Global::NS_DIR[:target]}/test_base_package-2_2.#{Global::ARCH_EXT}",
                                           "checking integrity of the archive file test_base_package-2_2.#{Global::ARCH_EXT}",
                                           "unpacking archive"
                                          ])
          end
        end

        context 'when all releases has an updated crystax version' do
          it 'installs updates for two installed releases' do
            repository_add_formula :target, 'test_base_package-3.rb:test_base_package.rb'
            crew_checked 'update'
            crew 'upgrade'
            expect(result).to eq(:ok)
            expect(out.split("\n")).to eq(["Will install: test_base_package:1_2, test_base_package:2_2",
                                           "downloading #{Global::DOWNLOAD_BASE}/#{Global::NS_DIR[:target]}/test_base_package-1_2.#{Global::ARCH_EXT}",
                                           "checking integrity of the archive file test_base_package-1_2.#{Global::ARCH_EXT}",
                                           "unpacking archive",
                                           "downloading #{Global::DOWNLOAD_BASE}/#{Global::NS_DIR[:target]}/test_base_package-2_2.#{Global::ARCH_EXT}",
                                           "checking integrity of the archive file test_base_package-2_2.#{Global::ARCH_EXT}",
                                           "unpacking archive"
                                          ])
          end
        end

        context 'when new release available' do
          it 'says and does nothing' do
            repository_add_formula :target, 'test_base_package-4.rb:test_base_package.rb'
            crew_checked 'update'
            crew 'upgrade'
            expect(result).to eq(:ok)
            expect(out).to eq('')
          end
        end
      end

      context 'when all releases are installed' do

        before do
          crew_checked 'install', '--all-versions', 'test_base_package'
        end

        context 'when one release has an updated crystax version' do
          it 'installs release with updated crystax version' do
            repository_add_formula :target, 'test_base_package-1.rb:test_base_package.rb'
            crew_checked 'update'
            crew 'upgrade'
            expect(result).to eq(:ok)
            expect(out.split("\n")).to eq(["Will install: test_base_package:2_2",
                                           "downloading #{Global::DOWNLOAD_BASE}/#{Global::NS_DIR[:target]}/test_base_package-2_2.#{Global::ARCH_EXT}",
                                           "checking integrity of the archive file test_base_package-2_2.#{Global::ARCH_EXT}",
                                           "unpacking archive"
                                          ])
          end
        end

        context 'when two releases has an updated crystax version' do
          it 'installs two releases with updated crystax version' do
            repository_add_formula :target, 'test_base_package-2.rb:test_base_package.rb'
            crew_checked 'update'
            crew 'upgrade'
            expect(result).to eq(:ok)
            expect(out.split("\n")).to eq(["Will install: test_base_package:1_2, test_base_package:2_2",
                                           "downloading #{Global::DOWNLOAD_BASE}/#{Global::NS_DIR[:target]}/test_base_package-1_2.#{Global::ARCH_EXT}",
                                           "checking integrity of the archive file test_base_package-1_2.#{Global::ARCH_EXT}",
                                           "unpacking archive",
                                           "downloading #{Global::DOWNLOAD_BASE}/#{Global::NS_DIR[:target]}/test_base_package-2_2.#{Global::ARCH_EXT}",
                                           "checking integrity of the archive file test_base_package-2_2.#{Global::ARCH_EXT}",
                                           "unpacking archive"
                                          ])
          end
        end

        context 'when all releases has an updated crystax version' do
          it 'installs updates for all releases' do
            repository_add_formula :target, 'test_base_package-3.rb:test_base_package.rb'
            crew_checked 'update'
            crew 'upgrade'
            expect(result).to eq(:ok)
            expect(out.split("\n")).to eq(["Will install: test_base_package:1_2, test_base_package:2_2, test_base_package:3_2",
                                           "downloading #{Global::DOWNLOAD_BASE}/#{Global::NS_DIR[:target]}/test_base_package-1_2.#{Global::ARCH_EXT}",
                                           "checking integrity of the archive file test_base_package-1_2.#{Global::ARCH_EXT}",
                                           "unpacking archive",
                                           "downloading #{Global::DOWNLOAD_BASE}/#{Global::NS_DIR[:target]}/test_base_package-2_2.#{Global::ARCH_EXT}",
                                           "checking integrity of the archive file test_base_package-2_2.#{Global::ARCH_EXT}",
                                           "unpacking archive",
                                           "downloading #{Global::DOWNLOAD_BASE}/#{Global::NS_DIR[:target]}/test_base_package-3_2.#{Global::ARCH_EXT}",
                                           "checking integrity of the archive file test_base_package-3_2.#{Global::ARCH_EXT}",
                                           "unpacking archive"
                                          ])
          end
        end

        context 'when new release available' do
          it 'says and does nothing' do
            repository_add_formula :target, 'test_base_package-4.rb:test_base_package.rb'
            crew_checked 'update'
            crew 'upgrade'
            expect(result).to eq(:ok)
            expect(out).to eq('')
          end
        end
      end
    end
  end

  context "when there are changes only in utilities" do

    context "when there is one new release for curl utility, which repplaces the installed one" do
      it "says about installing new release" do
        repository_clone
        repository_add_formula :host, 'curl-4.rb:curl.rb'
        crew_checked 'update'
        crew '-b', 'upgrade'
        curl_rel = Crew::Test::UTILS_RELEASES['curl'][3]
        file = "curl-#{curl_rel}-#{Global::PLATFORM_NAME}.#{Global::ARCH_EXT}"
        expect(result).to eq(:ok)
        expect(out.split("\n")).to eq(["Will install: curl:#{curl_rel}",
                                       "downloading #{Global::DOWNLOAD_BASE}/#{Global::NS_DIR[:host]}/#{file}",
                                       "checking integrity of the archive file #{file}",
                                       "unpacking archive",
                                       "Start postponed upgrade process",
                                       "Finishing CURL upgrade process",
                                       "= Removing old binary files",
                                       "= Removing old directories",
                                       "= Copying new files",
                                       "= Cleaning up"
                                      ])
        expect(pkg_cache_in?(:host, 'curl', curl_rel.version, curl_rel.crystax_version)).to eq(true)
      end
    end

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
                                       "unpacking archive",
                                       "Start postponed upgrade process",
                                       "Finishing CURL upgrade process",
                                       "= Removing old binary files",
                                       "= Removing old directories",
                                       "= Copying new files",
                                       "= Cleaning up"
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
                                       "unpacking archive",
                                       "Start postponed upgrade process",
                                       "Finishing CURL upgrade process",
                                       "= Removing old binary files",
                                       "= Removing old directories",
                                       "= Copying new files",
                                       "= Cleaning up"
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
                                       "Finishing CURL upgrade process",
                                       "= Removing old binary files",
                                       "= Removing old directories",
                                       "Finishing LIBARCHIVE upgrade process",
                                       "= Removing old binary files",
                                       "= Removing old directories",
                                       "Finishing RUBY upgrade process",
                                       "= Removing old binary files",
                                       "= Removing old directories",
                                       "= Copying new files",
                                       "= Cleaning up"
                                      ])
        expect(pkg_cache_in?(:host, 'libarchive', libarchive_new_rel.version, libarchive_new_rel.crystax_version)).to eq(true)
        expect(pkg_cache_in?(:host, 'curl',       curl_new_rel.version,       curl_new_rel.crystax_version)).to       eq(true)
        expect(pkg_cache_in?(:host, 'ruby',       ruby_new_rel.version,       ruby_new_rel.crystax_version)).to       eq(true)
      end
    end

    context 'when there changes only in multi-version base host packages (like gcc and llvm)' do

      before do
        FileUtils.rm_rf "#{Global::SERVICE_DIR}/test_tool"
        repository_add_formula :target, 'test_tool.rb'
        repository_clone
      end

      context 'when no releases are installed' do

        context 'when one release has an updated crystax version' do
          it 'says and does nothing' do
            repository_add_formula :target, 'test_tool-1.rb:test_tool.rb'
            crew_checked 'update'
            crew 'upgrade'
            expect(result).to eq(:ok)
            expect(out).to eq('')
          end
        end

        context 'when two releases has an updated crystax version' do
          it 'says and does nothing' do
            repository_add_formula :target, 'test_tool-2.rb:test_tool.rb'
            crew_checked 'update'
            crew 'upgrade'
            expect(result).to eq(:ok)
            expect(out).to eq('')
          end
        end

        context 'when all releases has an updated crystax version' do
          it 'says and does nothing' do
            repository_add_formula :target, 'test_tool-3.rb:test_tool.rb'
            crew_checked 'update'
            crew 'upgrade'
            expect(result).to eq(:ok)
            expect(out).to eq('')
          end
        end

        context 'when new release available' do
          it 'says and does nothing' do
            repository_add_formula :target, 'test_tool-4.rb:test_tool.rb'
            crew_checked 'update'
            crew 'upgrade'
            expect(result).to eq(:ok)
            expect(out).to eq('')
          end
        end
      end

      context 'when one release is installed' do

        before do
          crew_checked 'install', 'test_tool:2.0.0'
        end

        context 'when installed release has an updated crystax version' do
          it 'installs a release with updated crystax version' do
            repository_add_formula :target, 'test_tool-1.rb:test_tool.rb'
            crew_checked 'update'
            crew 'upgrade'
            archive = "test_tool-2.0.0_2-#{Global::PLATFORM_NAME}.#{Global::ARCH_EXT}"
            expect(result).to eq(:ok)
            expect(out.split("\n")).to eq(["Will install: test_tool:2.0.0_2",
                                           "downloading #{Global::DOWNLOAD_BASE}/#{Global::NS_DIR[:host]}/#{archive}",
                                           "checking integrity of the archive file #{archive}",
                                           "unpacking archive"
                                          ])
          end
        end

        context 'when two releases (one installed and one not installed) has an updated crystax version' do
          it 'installs a release with updated crystax version which was already installed' do
            repository_add_formula :target, 'test_tool-2.rb:test_tool.rb'
            crew_checked 'update'
            crew 'upgrade'
            archive = "test_tool-2.0.0_2-#{Global::PLATFORM_NAME}.#{Global::ARCH_EXT}"
            expect(result).to eq(:ok)
            expect(out.split("\n")).to eq(["Will install: test_tool:2.0.0_2",
                                           "downloading #{Global::DOWNLOAD_BASE}/#{Global::NS_DIR[:host]}/#{archive}",
                                           "checking integrity of the archive file #{archive}",
                                           "unpacking archive"
                                          ])
          end
        end

        context 'when all releases has an updated crystax version' do
          it 'installs a release with updated crystax version which was already installed' do
            repository_add_formula :target, 'test_tool-3.rb:test_tool.rb'
            crew_checked 'update'
            crew 'upgrade'
            archive = "test_tool-2.0.0_2-#{Global::PLATFORM_NAME}.#{Global::ARCH_EXT}"
            expect(result).to eq(:ok)
            expect(out.split("\n")).to eq(["Will install: test_tool:2.0.0_2",
                                           "downloading #{Global::DOWNLOAD_BASE}/#{Global::NS_DIR[:host]}/#{archive}",
                                           "checking integrity of the archive file #{archive}",
                                           "unpacking archive"
                                          ])
          end
        end

        context 'when new release available' do
          it 'says and does nothing' do
            repository_add_formula :target, 'test_tool-4.rb:test_tool.rb'
            crew_checked 'update'
            crew 'upgrade'
            expect(result).to eq(:ok)
            expect(out).to eq('')
          end
        end
      end

      context 'when two releases are installed' do

        before do
          crew_checked 'install', 'test_tool:1.0.0', 'test_tool:2.0.0'
        end

        context 'when one release has an updated crystax version' do
          it 'installs a release with updated crystax version' do
            repository_add_formula :target, 'test_tool-1.rb:test_tool.rb'
            crew_checked 'update'
            crew 'upgrade'
            archive = "test_tool-2.0.0_2-#{Global::PLATFORM_NAME}.#{Global::ARCH_EXT}"
            expect(result).to eq(:ok)
            expect(out.split("\n")).to eq(["Will install: test_tool:2.0.0_2",
                                           "downloading #{Global::DOWNLOAD_BASE}/#{Global::NS_DIR[:host]}/#{archive}",
                                           "checking integrity of the archive file #{archive}",
                                           "unpacking archive"
                                          ])
          end
        end

        context 'when two releases has an updated crystax version' do
          it 'installs two releases with updated crystax version' do
            repository_add_formula :target, 'test_tool-2.rb:test_tool.rb'
            crew_checked 'update'
            crew 'upgrade'
            archive_1 = "test_tool-1.0.0_2-#{Global::PLATFORM_NAME}.#{Global::ARCH_EXT}"
            archive_2 = "test_tool-2.0.0_2-#{Global::PLATFORM_NAME}.#{Global::ARCH_EXT}"
            expect(result).to eq(:ok)
            expect(out.split("\n")).to eq(["Will install: test_tool:1.0.0_2, test_tool:2.0.0_2",
                                           "downloading #{Global::DOWNLOAD_BASE}/#{Global::NS_DIR[:host]}/#{archive_1}",
                                           "checking integrity of the archive file #{archive_1}",
                                           "unpacking archive",
                                           "downloading #{Global::DOWNLOAD_BASE}/#{Global::NS_DIR[:host]}/#{archive_2}",
                                           "checking integrity of the archive file #{archive_2}",
                                           "unpacking archive"
                                          ])
          end
        end

        context 'when all releases has an updated crystax version' do
          it 'installs two releases with updated crystax version' do
            repository_add_formula :target, 'test_tool-3.rb:test_tool.rb'
            crew_checked 'update'
            crew 'upgrade'
            archive_1 = "test_tool-1.0.0_2-#{Global::PLATFORM_NAME}.#{Global::ARCH_EXT}"
            archive_2 = "test_tool-2.0.0_2-#{Global::PLATFORM_NAME}.#{Global::ARCH_EXT}"
            expect(result).to eq(:ok)
            expect(out.split("\n")).to eq(["Will install: test_tool:1.0.0_2, test_tool:2.0.0_2",
                                           "downloading #{Global::DOWNLOAD_BASE}/#{Global::NS_DIR[:host]}/#{archive_1}",
                                           "checking integrity of the archive file #{archive_1}",
                                           "unpacking archive",
                                           "downloading #{Global::DOWNLOAD_BASE}/#{Global::NS_DIR[:host]}/#{archive_2}",
                                           "checking integrity of the archive file #{archive_2}",
                                           "unpacking archive"
                                          ])
          end
        end

        context 'when new release available' do
          it 'says and does nothing' do
            repository_add_formula :target, 'test_tool-4.rb:test_tool.rb'
            crew_checked 'update'
            crew 'upgrade'
            expect(result).to eq(:ok)
            expect(out).to eq('')
          end
        end
      end

      context 'when all releases are installed' do

        before do
          crew_checked 'install', '--all-versions', 'test_tool'
        end

        context 'when one release has an updated crystax version' do
          it 'installs a release with updated crystax version' do
            repository_add_formula :target, 'test_tool-1.rb:test_tool.rb'
            crew_checked 'update'
            crew 'upgrade'
            archive = "test_tool-2.0.0_2-#{Global::PLATFORM_NAME}.#{Global::ARCH_EXT}"
            expect(result).to eq(:ok)
            expect(out.split("\n")).to eq(["Will install: test_tool:2.0.0_2",
                                           "downloading #{Global::DOWNLOAD_BASE}/#{Global::NS_DIR[:host]}/#{archive}",
                                           "checking integrity of the archive file #{archive}",
                                           "unpacking archive"
                                          ])
          end
        end

        context 'when two releases has an updated crystax version' do
          it 'installs two releases with updated crystax version' do
            repository_add_formula :target, 'test_tool-2.rb:test_tool.rb'
            crew_checked 'update'
            crew 'upgrade'
            archive_1 = "test_tool-1.0.0_2-#{Global::PLATFORM_NAME}.#{Global::ARCH_EXT}"
            archive_2 = "test_tool-2.0.0_2-#{Global::PLATFORM_NAME}.#{Global::ARCH_EXT}"
            expect(result).to eq(:ok)
            expect(out.split("\n")).to eq(["Will install: test_tool:1.0.0_2, test_tool:2.0.0_2",
                                           "downloading #{Global::DOWNLOAD_BASE}/#{Global::NS_DIR[:host]}/#{archive_1}",
                                           "checking integrity of the archive file #{archive_1}",
                                           "unpacking archive",
                                           "downloading #{Global::DOWNLOAD_BASE}/#{Global::NS_DIR[:host]}/#{archive_2}",
                                           "checking integrity of the archive file #{archive_2}",
                                           "unpacking archive"
                                          ])
          end
        end

        context 'when all releases has an updated crystax version' do
          it 'installs all releases with updated crystax version' do
            repository_add_formula :target, 'test_tool-3.rb:test_tool.rb'
            crew_checked 'update'
            crew 'upgrade'
            archive_1 = "test_tool-1.0.0_2-#{Global::PLATFORM_NAME}.#{Global::ARCH_EXT}"
            archive_2 = "test_tool-2.0.0_2-#{Global::PLATFORM_NAME}.#{Global::ARCH_EXT}"
            archive_3 = "test_tool-3.0.0_2-#{Global::PLATFORM_NAME}.#{Global::ARCH_EXT}"
            expect(result).to eq(:ok)
            expect(out.split("\n")).to eq(["Will install: test_tool:1.0.0_2, test_tool:2.0.0_2, test_tool:3.0.0_2",
                                           "downloading #{Global::DOWNLOAD_BASE}/#{Global::NS_DIR[:host]}/#{archive_1}",
                                           "checking integrity of the archive file #{archive_1}",
                                           "unpacking archive",
                                           "downloading #{Global::DOWNLOAD_BASE}/#{Global::NS_DIR[:host]}/#{archive_2}",
                                           "checking integrity of the archive file #{archive_2}",
                                           "unpacking archive",
                                           "downloading #{Global::DOWNLOAD_BASE}/#{Global::NS_DIR[:host]}/#{archive_3}",
                                           "checking integrity of the archive file #{archive_3}",
                                           "unpacking archive"
                                          ])
          end
        end

        context 'when new release available' do
          it 'says and does nothing' do
            repository_add_formula :target, 'test_tool-4.rb:test_tool.rb'
            crew_checked 'update'
            crew 'upgrade'
            expect(result).to eq(:ok)
            expect(out).to eq('')
          end
        end
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
                                       "unpacking archive", "Start postponed upgrade process",
                                       "Finishing CURL upgrade process",
                                       "= Removing old binary files",
                                       "= Removing old directories",
                                       "= Copying new files",
                                       "= Cleaning up"
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
                                       "Finishing CURL upgrade process",
                                       "= Removing old binary files",
                                       "= Removing old directories",
                                       "Finishing LIBARCHIVE upgrade process",
                                       "= Removing old binary files",
                                       "= Removing old directories",
                                       "Finishing RUBY upgrade process",
                                       "= Removing old binary files",
                                       "= Removing old directories",
                                       "= Copying new files",
                                       "= Cleaning up"
                                      ])
        expect(pkg_cache_in?(:host, 'libarchive', libarchive_new_rel.version, libarchive_new_rel.crystax_version)).to eq(true)
        expect(pkg_cache_in?(:host, 'curl',       curl_new_rel.version,       curl_new_rel.crystax_version)).to       eq(true)
        expect(pkg_cache_in?(:host, 'ruby',       ruby_new_rel.version,       ruby_new_rel.crystax_version)).to       eq(true)
      end
    end
  end
end
