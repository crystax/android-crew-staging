# must be first file included
require_relative 'spec_helper.rb'


describe "crew info" do
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
      crew 'info'
      expect(exitstatus).to_not be_zero
      expect(err.split("\n")[0]).to eq('error: this command requires a formula argument')
    end
  end

  context "non existing name" do
    it "outputs error message" do
      crew 'info', 'foo'
      expect(exitstatus).to_not be_zero
      expect(err.split("\n")[0]).to eq('error: no available formula for foo')
    end
  end

  context "about ruby, all utilities with one release each" do
    it "outputs info about ruby" do
      crew 'info', 'ruby'
      ruby_rel = Crew::Test::UTILS_RELEASES['ruby'][0]
      expect(result).to eq(:ok)
      expect(out.split("\n")).to eq(["Name:               ruby",
                                     "Namespace:          host",
                                     "Formula:            #{Global::FORMULA_DIR}/#{Global::NS_DIR[:host]}/ruby.rb",
                                     "Homepage:           https://www.ruby-lang.org/",
                                     "Description:        Powerful, clean, object-oriented scripting language",
                                     "Class:              ruby",
                                     "Releases:           #{ruby_rel.version} #{ruby_rel.crystax_version} (*)",
                                     "Dependencies:       none",
                                     "Build dependencies: zlib (*), openssl (*), libssh2 (*), libgit2 (*)"
                                    ])
    end
  end

  context "about all crew utilities, all utilities with one release each" do
    it "outputs info about crew utilities" do
      crew 'info', 'curl', 'bsdtar','ruby'
      curl_rel = Crew::Test::UTILS_RELEASES['curl'][0]
      bsdtar_rel = Crew::Test::UTILS_RELEASES['libarchive'][0]
      ruby_rel = Crew::Test::UTILS_RELEASES['ruby'][0]
      expect(result).to eq(:ok)
      expect(out.split("\n")).to eq(["Name:               curl",
                                     "Namespace:          host",
                                     "Formula:            #{Global::FORMULA_DIR}/#{Global::NS_DIR[:host]}/curl.rb",
                                     "Homepage:           http://curl.haxx.se/",
                                     "Description:        Get a file from an HTTP, HTTPS or FTP server",
                                     "Class:              curl",
                                     "Releases:           #{curl_rel.version} #{curl_rel.crystax_version} (*)",
                                     "Dependencies:       none",
                                     "Build dependencies: zlib (*), openssl (*), libssh2 (*)",
                                     "",
                                     "Name:               bsdtar",
                                     "Namespace:          host",
                                     "Formula:            #{Global::FORMULA_DIR}/#{Global::NS_DIR[:host]}/libarchive.rb",
                                     "Homepage:           http://www.libarchive.org",
                                     "Description:        bsdtar utility from multi-format archive and compression library libarchive",
                                     "Class:              bsdtar",
                                     "Releases:           #{bsdtar_rel.version} #{bsdtar_rel.crystax_version} (*)",
                                     "Dependencies:       none",
                                     "Build dependencies: xz",
                                     "",
                                     "Name:               ruby",
                                     "Namespace:          host",
                                     "Formula:            #{Global::FORMULA_DIR}/#{Global::NS_DIR[:host]}/ruby.rb",
                                     "Homepage:           https://www.ruby-lang.org/",
                                     "Description:        Powerful, clean, object-oriented scripting language",
                                     "Class:              ruby",
                                     "Releases:           #{ruby_rel.version} #{ruby_rel.crystax_version} (*)",
                                     "Dependencies:       none",
                                     "Build dependencies: zlib (*), openssl (*), libssh2 (*), libgit2 (*)"
                                    ])
    end
  end

  context "formula with one release and no dependencies, not installed" do
    it "outputs info about one not installed release with no dependencies" do
      copy_packages_formulas 'libone.rb'
      crew 'info', 'libone'
      expect(result).to eq(:ok)
      expect(out.split("\n")).to eq(["Name:               libone",
                                     "Namespace:          target",
                                     "Formula:            #{Global::FORMULA_DIR}/#{Global::NS_DIR[:target]}/libone.rb",
                                     "Homepage:           http://www.libone.org",
                                     "Description:        Library One",
                                     "Class:              libone",
                                     "Releases:           1.0.0 1",
                                     "Dependencies:       none",
                                     "Build dependencies: none"
                                    ])
    end
  end

  context "formula with two releases and one dependency, none installed" do
    it "outputs info about two releases and one dependency" do
      copy_packages_formulas 'libone.rb', 'libtwo.rb'
      crew 'info', 'libtwo'
      expect(result).to eq(:ok)
      exp = ["Name:               libtwo",
             "Namespace:          target",
             "Formula:            #{Global::FORMULA_DIR}/#{Global::NS_DIR[:target]}/libtwo.rb",
             "Homepage:           http://www.libtwo.org",
             "Description:        Library Two",
             "Class:              libtwo",
             "Releases:           1.1.0 1, 2.2.0 1",
             "Dependencies:       libone",
             "Build dependencies: none"
            ]
      got = out.split("\n")
      got.each_with_index { |g, i| expect(g).to match(exp[i]) }
    end
  end

  context "formula with two releases and one dependency, none installed, show only versions" do
    it "outputs info about two releases" do
      copy_packages_formulas 'libone.rb', 'libtwo.rb'
      crew 'info', '--versions-only', 'libtwo'
      expect(result).to eq(:ok)
      expect(out.strip).to eq('1.1.0_1 2.2.0_1')
    end
  end

  context "formula with two releases and one dependency, none installed, show only path" do
    it "outputs info about two releases" do
      copy_packages_formulas 'libone.rb', 'libtwo.rb'
      crew 'info', '--path-only', 'libtwo'
      expect(result).to eq(:ok)
      expect(out.strip).to eq("#{Global::FORMULA_DIR}/#{Global::NS_DIR[:target]}/libtwo.rb")
    end
  end

  context "formula with three releases and two dependencies, none installed" do
    it "outputs info about three releases and two dependencies" do
      copy_packages_formulas 'libone.rb', 'libtwo.rb', 'libthree.rb'
      crew 'info', 'libthree'
      expect(result).to eq(:ok)
      exp = ["Name:               libthree",
             "Namespace:          target",
             "Formula:            #{Global::FORMULA_DIR}/#{Global::NS_DIR[:target]}/libthree.rb",
             "Homepage:           http://www.libthree.org",
             "Description:        Library Three",
             "Class:              libthree",
             "Releases:           1.1.1 1, 2.2.2 1, 3.3.3 1",
             "Dependencies:       libone, libtwo",
             "Build dependencies: none"
            ]
      got = out.split("\n")
      got.each_with_index { |g, i| expect(g).to match(exp[i]) }
    end
  end

  context "formula with three releases and two dependencies, both dependencies installed" do
    it "outputs info about two releases and one dependency" do
      pkg_cache_add_package_with_formula 'libone'
      pkg_cache_add_package_with_formula 'libtwo'
      pkg_cache_add_package_with_formula 'libthree'
      crew_checked 'install', 'libtwo'
      crew 'info', 'libthree'
      expect(result).to eq(:ok)
      exp = ["Name:               libthree",
             "Namespace:          target",
             "Formula:            #{Global::FORMULA_DIR}/#{Global::NS_DIR[:target]}/libthree.rb",
             "Homepage:           http://www.libthree.org",
             "Description:        Library Three",
             "Class:              libthree",
             "Releases:           1.1.1 1, 2.2.2 1, 3.3.3 1",
             "Dependencies:       libone (*), libtwo (*)",
             "Build dependencies: none"
            ]
      got = out.split("\n")
      got.each_with_index { |g, i| expect(g).to match(exp[i]) }
    end
  end
end
