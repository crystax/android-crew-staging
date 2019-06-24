# coding: utf-8
# must be first file included
require_relative 'spec_helper.rb'


describe "crew list" do
  before(:all) do
    environment_init
    ndk_init
  end

  before(:each) do
    clean_hold
    clean_cache
    repository_init
    repository_clone
    # make sure that tools installed without dev files
    pkg_cache_add_tool 'curl', update: false
    pkg_cache_add_tool 'ruby', update: false
    crew_checked '-W install --no-check-shasum --cache-only --force host/curl host/ruby'
  end

  context "when given bad arguments" do

    context "with 3 incorrect arguments" do
      it "outputs error message" do
        crew 'list', 'a', 'b', 'c'
        expect(exitstatus).to_not be_zero
        expect(err.split("\n")[0]).to match(/error: .*/)
        expect(out).to eq('')
      end
    end

    context "with 2 incorrect arguments" do
      it "outputs error message" do
        crew 'list', 'a', 'b'
        expect(exitstatus).to_not be_zero
        expect(err.split("\n")[0]).to match(/error: .*/)
        expect(out).to eq('')
      end
    end

    context "with one incorrect argument" do
      it "outputs error message" do
        crew 'list', 'a'
        expect(exitstatus).to_not be_zero
        expect(err.split("\n")[0]).to match(/error: .*/)
        expect(out).to eq('')
      end
    end
  end

  context "with --packages argument" do

    context "no formulas and empty hold" do
      it "outputs 'Packages:' title" do
        crew 'list', '--packages'
        expect(result).to eq(:ok)
        expect(out.split("\n")[0]).to eq('Packages:')
      end
    end

    context "no formulas and empty hold and --no-title option" do
      it "outputs nothing" do
        crew 'list', '--packages', '--no-title'
        expect(result).to eq(:ok)
        expect(out).to eq('')
      end
    end

    context "empty hold, one formula with one release" do
      it "outputs info about one not installed release" do
        copy_package_formulas 'libone.rb'
        crew 'list', '--packages', '--no-title'
        expect(result).to eq(:ok)
        expect(out.split("\n")).to eq(["   libone  1.0.0  1"])
      end
    end

    context "empty hold, three formulas with one, two and three releases" do
      it "outputs info about all available releases" do
        copy_package_formulas 'libone.rb', 'libtwo.rb', 'libthree.rb'
        crew 'list', '--packages', '--no-title'
        expect(result).to eq(:ok)
        expect(out.split("\n")).to eq(["   libone    1.0.0  1",
                                       "   libthree  1.1.1  1",
                                       "   libthree  2.2.2  1",
                                       "   libthree  3.3.3  1",
                                       "   libtwo    1.1.0  1",
                                       "   libtwo    2.2.0  1"])
      end
    end

    context "one formula with one release installed" do
      it "outputs info about one existing release and marks it as installed" do
        pkg_cache_add_package_with_formula 'libone'
        crew_checked 'install', 'libone'
        crew 'list', '--packages', '--no-title'
        expect(result).to eq(:ok)
        expect(out.split("\n")).to eq([" * libone  1.0.0  1"])
      end
    end

    context "one formula with 4 releases and one release installed" do
      it "outputs info about 4 releases and marks one as installed" do
        pkg_cache_add_package_with_formula 'libfour'
        crew_checked 'install', 'libfour:4.4.4'
        crew 'list', '--packages', '--no-title'
        expect(result).to eq(:ok)
        expect(out.split("\n")).to eq(["   libfour  1.1.1  1",
                                       "   libfour  1.1.2  2",
                                       "   libfour  2.2.2  2",
                                       "   libfour  3.3.3  3",
                                       " * libfour  4.4.4  4"])
      end
    end

    context "three formulas with one, two and three releases, one of each releases installed" do
      it "outputs info about six releases and marks three as installed" do
        pkg_cache_add_package_with_formula 'libone'
        pkg_cache_add_package_with_formula 'libtwo'
        pkg_cache_add_package_with_formula 'libthree', release: Release.new('1.1.1', 1)
        crew_checked 'install', 'libone', 'libtwo', 'libthree:1.1.1'
        crew 'list', '--packages', '--no-title'
        expect(result).to eq(:ok)
        expect(out.split("\n")).to eq([" * libone    1.0.0  1",
                                       " * libthree  1.1.1  1",
                                       "   libthree  2.2.2  1",
                                       "   libthree  3.3.3  1",
                                       "   libtwo    1.1.0  1",
                                       " * libtwo    2.2.0  1"])
      end
    end

    context "four formulas with many releases, latest release of each formula installed" do
      it "outputs info about existing and installed releases" do
        pkg_cache_add_package_with_formula 'libone'
        pkg_cache_add_package_with_formula 'libtwo'
        pkg_cache_add_package_with_formula 'libthree'
        pkg_cache_add_package_with_formula 'libfour'
        crew_checked 'install', 'libone', 'libtwo', 'libthree', 'libfour'
        crew 'list', '--packages', '--no-title'
        expect(result).to eq(:ok)
        expect(out.split("\n")).to eq(["   libfour   1.1.1  1",
                                       "   libfour   1.1.2  2",
                                       "   libfour   2.2.2  2",
                                       "   libfour   3.3.3  3",
                                       " * libfour   4.4.4  4",
                                       " * libone    1.0.0  1",
                                       "   libthree  1.1.1  1",
                                       "   libthree  2.2.2  1",
                                       " * libthree  3.3.3  1",
                                       "   libtwo    1.1.0  1",
                                       " * libtwo    2.2.0  1"])
      end
    end
  end

  context "with --tools argument" do

    context "when there is one release of every utility and no dev files installed" do
      it "outputs info about installed utilities" do
        crew 'list', '--tools', '--no-title'
        expect(result).to eq(:ok)
        got = out.split("\n")
        exp = [/ \* binutils\s+\d+\.\d+\s+\d+/,
               / \* bzip2\s+\d+\.\d+\.\d+\s+\d+/,
               /   cloog\s+\d+\.\d+\.\d+\s+\d+/,
               /   cloog-old\s+\d+\.\d+\.\d+\s+\d+/,
               / \* curl  \s+#{Crew::Test::UTILS_RELEASES['curl'][0].version}\s+#{Crew::Test::UTILS_RELEASES['curl'][0].crystax_version}\s+no dev files\s*$/,
               /   expat\s+\d+\.\d+\.\d+\s+\d+/,
               / [ \*] gcc\s+\d+\s+\d+/,
               /   gmp\s+\d+\.\d+\.\d+\s+\d+/,
               /   isl\s+\d+\.\d+\s+\d+/,
               /   isl-old\s+\d+\.\d+\.\d+\s+\d+/,
               / \* libarchive\s+#{Crew::Test::UTILS_RELEASES['libarchive'][0].version}\s+#{Crew::Test::UTILS_RELEASES['libarchive'][0].crystax_version}/,
               /   libedit\s+\d+-\d+\.\d+\s+\d+/,
               / \* libgit2\s+\d+\.\d+\.\d+\s+\d+\s+no dev files\s*$/,
               / \* libssh2\s+\d+\.\d+\.\d+\s+\d+\s+no dev files\s*$/,
               / [ \*] llvm\s+\d+\.\d+\s+\d+/,
               / \* make\s+\d+\.\d+\s+\d+/,
               /   mpc\s+\d+\.\d+\.\d+\s+\d+/,
               /   mpfr\s+\d+\.\d+\.\d+\s+\d+/,
               / \* nawk\s+\d+\s+\d+/,
               / \* ndk-base\s+\d+\s+\d+/,
               / \* ndk-depends\s+\d+\s+\d+/,
               / \* ndk-stack\s+\d+\s+\d+/,
               / \* openssl\s+\d+\.\d+\.\d+[a-z]\s+\d+/,
               /   ppl\s+\d+\.\d+\s+\d+/,
               / \* python\s+\d+\.\d+\.\d+\s+\d+\s+no dev files\s*$/,
               / \* ruby  \s+#{Crew::Test::UTILS_RELEASES['ruby'][0].version}\s+#{Crew::Test::UTILS_RELEASES['ruby'][0].crystax_version}\s+no dev files\s*$/,
               / \* xz\s+\d+\.\d+\.\d+\s+\d+/,
               / \* yasm\s+\d+\.\d+\.\d+\s+\d+/,
               / \* zlib\s+\d+\.\d+\.\d+\s+\d+\s+no dev files\s*$/
              ]
        expect(got.size).to eq(exp.size)
        got.each_with_index { |g, i| expect(g).to match(exp[i]) }
      end
    end

    context "when there is one release of every utility and curl dev files installed" do
      it "outputs info about installed utilities" do
        pkg_cache_add_tool 'curl'
        crew_checked '-W install --cache-only --with-dev-files --force curl'
        crew 'list', '--tools', '--no-title'
        expect(result).to eq(:ok)
        got = out.split("\n")
        exp = [/ \* binutils\s+\d+\.\d+\s+\d+/,
               / \* bzip2\s+\d+\.\d+\.\d+\s+\d+/,
               /   cloog\s+\d+\.\d+\.\d+\s+\d+/,
               /   cloog-old\s+\d+\.\d+\.\d+\s+\d+/,
               / \* curl  \s+#{Crew::Test::UTILS_RELEASES['curl'][0].version}\s+#{Crew::Test::UTILS_RELEASES['curl'][0].crystax_version}\s+dev files\s*$/,
               /   expat\s+\d+\.\d+\.\d+\s+\d+/,
               / [ \*] gcc\s+\d+\s+\d+/,
               /   gmp\s+\d+\.\d+\.\d+\s+\d+/,
               /   isl\s+\d+\.\d+\s+\d+/,
               /   isl-old\s+\d+\.\d+\.\d+\s+\d+/,
               / \* libarchive\s+#{Crew::Test::UTILS_RELEASES['libarchive'][0].version}\s+#{Crew::Test::UTILS_RELEASES['libarchive'][0].crystax_version}/,
               /   libedit\s+\d+-\d+\.\d+\s+\d+/,
               / \* libgit2\s+\d+\.\d+\.\d+\s+\d+\s+no dev files\s*$/,
               / \* libssh2\s+\d+\.\d+\.\d+\s+\d+\s+no dev files\s*$/,
               / [ \*] llvm\s+\d+\.\d+\s+\d+/,
               / \* make\s+\d+\.\d+\s+\d+/,
               /   mpc\s+\d+\.\d+\.\d+\s+\d+/,
               /   mpfr\s+\d+\.\d+\.\d+\s+\d+/,
               / \* nawk\s+\d+\s+\d+/,
               / \* ndk-base\s+\d+\s+\d+/,
               / \* ndk-depends\s+\d+\s+\d+/,
               / \* ndk-stack\s+\d+\s+\d+/,
               / \* openssl\s+\d+\.\d+\.\d+[a-z]\s+\d+/,
               /   ppl\s+\d+\.\d+\s+\d+/,
               / \* python\s+\d+\.\d+\.\d+\s+\d+\s+no dev files\s*$/,
               / \* ruby  \s+#{Crew::Test::UTILS_RELEASES['ruby'][0].version}\s+#{Crew::Test::UTILS_RELEASES['ruby'][0].crystax_version}\s+no dev files\s*$/,
               / \* xz\s+\d+\.\d+\.\d+\s+\d+/,
               / \* yasm\s+\d+\.\d+\.\d+\s+\d+/,
               / \* zlib\s+\d+\.\d+\.\d+\s+\d+\s+no dev files\s*$/
              ]
        expect(got.size).to eq(exp.size)
        got.each_with_index { |g, i| expect(g).to match(exp[i]) }
      end
    end

    # todo:
    # context "when more than one release of one utility installed" do
    # end
  end

  context "whithout arguments" do

    context "when some formulas are with many releases, and there is one release of every utility" do
      it "outputs info about existing and installed releases" do
        pkg_cache_add_package_with_formula 'libone'
        pkg_cache_add_package_with_formula 'libtwo'
        pkg_cache_add_package_with_formula 'libthree'
        pkg_cache_add_package_with_formula 'libfour'
        crew_checked 'install', 'libone', 'libtwo', 'libthree', 'libfour'
        crew 'list'
        expect(result).to eq(:ok)
        got = out.split("\n")
        exp = ["Tools:",
               / \* binutils\s+\d+\.\d+\s+\d+/,
               / \* bzip2\s+\d+\.\d+\.\d+\s+\d+/,
               /   cloog\s+\d+\.\d+\.\d+\s+\d+/,
               /   cloog-old\s+\d+\.\d+\.\d+\s+\d+/,
               / \* curl  \s+#{Crew::Test::UTILS_RELEASES['curl'][0].version}\s+#{Crew::Test::UTILS_RELEASES['curl'][0].crystax_version}\s+no dev files\s*$/,
               /   expat\s+\d+\.\d+\.\d+\s+\d+/,
               / [ \*] gcc\s+\d+\s+\d+/,
               /   gmp\s+\d+\.\d+\.\d+\s+\d+/,
               /   isl\s+\d+\.\d+\s+\d+/,
               /   isl-old\s+\d+\.\d+\.\d+\s+\d+/,
               / \* libarchive\s+#{Crew::Test::UTILS_RELEASES['libarchive'][0].version}\s+#{Crew::Test::UTILS_RELEASES['libarchive'][0].crystax_version}/,
               /   libedit\s+\d+-\d+\.\d+\s+\d+/,
               / \* libgit2\s+\d+\.\d+\.\d+\s+\d+\s+no dev files\s*$/,
               / \* libssh2\s+\d+\.\d+\.\d+\s+\d+\s+no dev files\s*$/,
               / [ \*] llvm\s+\d+\.\d+\s+\d+/,
               / \* make\s+\d+\.\d+\s+\d+/,
               /   mpc\s+\d+\.\d+\.\d+\s+\d+/,
               /   mpfr\s+\d+\.\d+\.\d+\s+\d+/,
               / \* nawk\s+\d+\s+\d+/,
               / \* ndk-base\s+\d+\s+\d+/,
               / \* ndk-depends\s+\d+\s+\d+/,
               / \* ndk-stack\s+\d+\s+\d+/,
               / \* openssl\s+\d+\.\d+\.\d+[a-z]\s+\d+/,
               /   ppl\s+\d+\.\d+\s+\d+/,
               / \* python\s+\d+\.\d+\.\d+\s+\d+\s+no dev files/,
               / \* ruby  \s+#{Crew::Test::UTILS_RELEASES['ruby'][0].version}\s+#{Crew::Test::UTILS_RELEASES['ruby'][0].crystax_version}\s+no dev files\s*$/,
               / \* xz\s+\d+\.\d+\.\d+\s+\d+/,
               / \* yasm\s+\d+\.\d+\.\d+\s+\d+/,
               / \* zlib\s+\d+\.\d+\.\d+\s+\d+\s+no dev files\s*$/,
               "Packages:",
               "   libfour   1.1.1  1",
               "   libfour   1.1.2  2",
               "   libfour   2.2.2  2",
               "   libfour   3.3.3  3",
               " * libfour   4.4.4  4",
               " * libone    1.0.0  1",
               "   libthree  1.1.1  1",
               "   libthree  2.2.2  1",
               " * libthree  3.3.3  1",
               "   libtwo    1.1.0  1",
               " * libtwo    2.2.0  1"
              ]
        expect(got.size).to eq(exp.size)
        got.each_with_index { |g, i| expect(g).to match(exp[i]) }
      end
    end
  end
end
