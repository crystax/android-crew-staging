# must be first file included
require_relative 'spec_helper.rb'

require_relative '../library/github.rb'


describe "crew install" do
  before(:all) do
    ndk_init
  end

  before(:each) do
    clean_hold
    clean_cache
    environment_init
    repository_init
    repository_clone
  end

  context "without argument" do
    it "outputs error message" do
      crew 'install'
      expect(exitstatus).to_not be_zero
      expect(err.split("\n")[0]).to eq('error: this command requires a formula argument')
      expect(pkg_cache_empty?).to eq(true)
    end
  end

  context "non existing name" do
    it "outputs error message" do
      crew 'install', 'foo'
      expect(exitstatus).to_not be_zero
      expect(err.split("\n")[0]).to eq('error: no available formula for foo')
      expect(pkg_cache_empty?).to eq(true)
    end
  end

  context "existing formula with one release and bad sha256 sum of the downloaded file" do
    it "outputs error message" do
      rel = pkg_cache_add_package_with_formula('libbad')
      pkg_cache_corrupt_file :target, 'libbad', rel
      crew_checked 'shasum', '--update'
      pkg_cache_del_file :target, 'libbad', rel
      file = File.join(Global::PKG_CACHE_DIR, Global::NS_DIR[:target], "libbad-#{rel}.#{Global::ARCH_EXT}")
      crew 'install', 'libbad'
      expect(exitstatus).to_not be_zero
      expect(err.split("\n")[0]).to eq("error: bad SHA256 sum of the file #{file}")
      expect(pkg_cache_in?(:target, 'libbad', rel.version, rel.crystax_version)).to eq(true)
    end
  end

  context "existing formula with one release, no dependencies, specifing only name" do
    it "outputs info about installing existing release" do
      rel = pkg_cache_add_package_with_formula('libone', update: true, delete: true)
      file = package_archive_name('libone', rel)
      url = "#{Global::DOWNLOAD_BASE}/packages/#{file}"
      crew 'install', 'libone'
      expect(result).to eq(:ok)
      expect(out).to eq("calculating dependencies for libone: \n"          \
                        "  dependencies to install: \n"                    \
                        "downloading #{url}\n"                             \
                        "checking integrity of the archive file #{file}\n" \
                        "unpacking archive\n")
      expect(pkg_cache_has_package?('libone', rel)).to eq(true)
    end
  end

  context "existing formula with one release, no dependencies, specifing name and version" do
    it "outputs info about installing existing release" do
      rel = pkg_cache_add_package_with_formula('libone', update: true, delete: true)
      file = package_archive_name('libone', rel)
      url = "#{Global::DOWNLOAD_BASE}/packages/#{file}"
      crew 'install', 'libone:1.0.0'
      expect(result).to eq(:ok)
      expect(out).to eq("calculating dependencies for libone: \n"          \
                        "  dependencies to install: \n"                    \
                        "downloading #{url}\n"                             \
                        "checking integrity of the archive file #{file}\n" \
                        "unpacking archive\n")
      expect(pkg_cache_has_package?('libone', rel)).to eq(true)
    end
  end

  context "existing formula with one release, no dependencies, specifing full release info" do
    it "outputs info about installing existing release" do
      rel = pkg_cache_add_package_with_formula('libone', update: true, delete: true)
      file = package_archive_name('libone', rel)
      url = "#{Global::DOWNLOAD_BASE}/packages/#{file}"
      crew 'install', 'libone:1.0.0:1'
      expect(result).to eq(:ok)
      expect(out).to eq("calculating dependencies for libone: \n"          \
                        "  dependencies to install: \n"                    \
                        "downloading #{url}\n"                             \
                        "checking integrity of the archive file #{file}\n" \
                        "unpacking archive\n")
      expect(pkg_cache_has_package?('libone', rel)).to eq(true)
    end
  end

  context "existing formula with one release, no dependencies, specifing non existing version" do
    it "outputs info about installing existing release" do
      copy_packages_formulas 'libone.rb'
      crew 'install', 'libone:2.0.0'
      expect(exitstatus).to_not be_zero
      expect(err.split("\n")[0]).to eq('error: libone has no release with version 2.0.0')
    end
  end

  context "existing formula with two versions and one dependency" do
    it "outputs info about installing dependency and the latest version" do
      libone_rel = pkg_cache_add_package_with_formula('libone', update: true, delete: true)
      libtwo_rel = pkg_cache_add_package_with_formula('libtwo', update: true, delete: true)
      depfile = package_archive_name('libone', libone_rel)
      depurl = "#{Global::DOWNLOAD_BASE}/packages/#{depfile}"
      resfile = package_archive_name('libtwo', libtwo_rel)
      resurl = "#{Global::DOWNLOAD_BASE}/packages/#{resfile}"
      crew 'install', 'libtwo'
      expect(result).to eq(:ok)
      expect(out).to eq("calculating dependencies for libtwo: \n"             \
                        "  dependencies to install: libone\n"                 \
                        "installing dependencies for libtwo:\n"               \
                        "downloading #{depurl}\n"                             \
                        "checking integrity of the archive file #{depfile}\n" \
                        "unpacking archive\n"                                 \
                        "\n"                                                  \
                        "downloading #{resurl}\n"                             \
                        "checking integrity of the archive file #{resfile}\n" \
                        "unpacking archive\n")
      expect(pkg_cache_has_package?('libone', libone_rel)).to eq(true)
      expect(pkg_cache_has_package?('libtwo', libtwo_rel)).to eq(true)
    end
  end

  context "specific release of the existing formula with three releases and two dependencies" do
    it "outputs info about installing dependencies and the specified release" do
      libone_rel   = pkg_cache_add_package_with_formula('libone',   update: true, delete: true)
      libtwo_rel   = pkg_cache_add_package_with_formula('libtwo',   update: true, delete: true, release: Release.new('2.2.0', 1))
      libthree_rel = pkg_cache_add_package_with_formula('libthree', update: true, delete: true, release: Release.new('2.2.2', 1))
      depfile1 = package_archive_name('libone',   libone_rel)
      depfile2 = package_archive_name('libtwo',   libtwo_rel)
      resfile  = package_archive_name('libthree', libthree_rel)
      depurl1 = "#{Global::DOWNLOAD_BASE}/packages/#{depfile1}"
      depurl2 = "#{Global::DOWNLOAD_BASE}/packages/#{depfile2}"
      resurl  = "#{Global::DOWNLOAD_BASE}/packages/#{resfile}"
      crew 'install', 'libthree:2.2.2:1'
      expect(result).to eq(:ok)
      expect(out).to eq("calculating dependencies for libthree: \n"            \
                        "  dependencies to install: libone, libtwo\n"          \
                        "installing dependencies for libthree:\n"              \
                        "downloading #{depurl1}\n"                             \
                        "checking integrity of the archive file #{depfile1}\n" \
                        "unpacking archive\n"                                  \
                        "downloading #{depurl2}\n"                             \
                        "checking integrity of the archive file #{depfile2}\n" \
                        "unpacking archive\n"                                  \
                        "\n"                                                   \
                        "downloading #{resurl}\n"                              \
                        "checking integrity of the archive file #{resfile}\n"  \
                        "unpacking archive\n")
      expect(pkg_cache_has_package?('libone',   libone_rel)).to   eq(true)
      expect(pkg_cache_has_package?('libtwo',   libtwo_rel)).to   eq(true)
      expect(pkg_cache_has_package?('libthree', libthree_rel)).to eq(true)
    end
  end

  context "existing formula with one release from the cache" do
    it "outputs info about using cached file" do
      rel = pkg_cache_add_package_with_formula('libone')
      file = package_archive_name('libone', rel)
      crew 'install', 'libone'
      expect(result).to eq(:ok)
      expect(out).to eq("calculating dependencies for libone: \n"          \
                        "  dependencies to install: \n"                    \
                        "using cached file #{file}\n"                      \
                        "checking integrity of the archive file #{file}\n" \
                        "unpacking archive\n")
      expect(pkg_cache_has_package?('libone', rel)).to eq(true)
    end
  end

  context "existing formula with four versions, 11 releases, specifying only name" do
    it "outputs info about installing latest release" do
      rel = pkg_cache_add_package_with_formula('libfour', update: true, delete: true)
      file = package_archive_name('libfour', rel)
      url = "#{Global::DOWNLOAD_BASE}/packages/#{file}"
      crew 'install', 'libfour'
      expect(result).to eq(:ok)
      expect(out).to eq("calculating dependencies for libfour: \n"         \
                        "  dependencies to install: \n"                    \
                        "downloading #{url}\n"                             \
                        "checking integrity of the archive file #{file}\n" \
                        "unpacking archive\n")
      expect(pkg_cache_has_package?('libfour', rel)).to eq(true)
    end
  end

  context "existing formula with four versions, specifying name and version" do
    it "outputs info about installing latest crystax_version of the specified version" do
      rel = pkg_cache_add_package_with_formula('libfour', update: true, delete: true, release: Release.new('3.3.3', 3))
      file = package_archive_name('libfour', rel)
      url = "#{Global::DOWNLOAD_BASE}/packages/#{file}"
      crew 'install', 'libfour:3.3.3'
      expect(result).to eq(:ok)
      expect(out).to eq("calculating dependencies for libfour: \n"         \
                        "  dependencies to install: \n"                    \
                        "downloading #{url}\n"                             \
                        "checking integrity of the archive file #{file}\n" \
                        "unpacking archive\n")
      expect(pkg_cache_has_package?('libfour', rel)).to eq(true)
    end
  end

  context 'origin points to crew-staging repository on GitHub' do

    context 'test package from release assets' do
      it 'outputs info about installing test_package 1.0.0:1' do
        rel = pkg_cache_add_package_with_formula('test_package', update: true, delete: true)
        file = package_archive_name('test_package', rel)
        ENV['CREW_DOWNLOAD_BASE'] = nil
        set_origin_url GitHub::STAGING_HTTPS_URL
        crew_checked 'env',  '--download-base'
        url = "#{out.strip}/packages.#{file}"
        crew 'install', 'test_package'
        expect(result).to eq(:ok)
        expect(out).to eq("calculating dependencies for test_package: \n"    \
                          "  dependencies to install: \n"                    \
                          "downloading #{url}\n"                             \
                          "checking integrity of the archive file #{file}\n" \
                          "unpacking archive\n")
        expect(pkg_cache_has_package?('test_package', rel)).to eq(true)
      end
    end

    context 'test tool from release assets' do
      it 'outputs info about installing test_tool 1.0.0:1' do
        rel = pkg_cache_add_tool_with_formula('test_tool', update: true, delete: true)
        file = tool_archive_name('test_tool', rel)
        ENV['CREW_DOWNLOAD_BASE'] = nil
        set_origin_url GitHub::STAGING_HTTPS_URL
        crew_checked 'env',  '--download-base'
        url = "#{out.strip}/tools.#{file}"
        crew 'install', 'test_tool'
        expect(result).to eq(:ok)
        expect(out.split("\n")).to eq(["calculating dependencies for test_tool: ",
                                       "  dependencies to install: ",
                                       "downloading #{url}",
                                       "checking integrity of the archive file #{file}",
                                       "unpacking archive"
                                      ])
        expect(pkg_cache_has_tool?('test_tool', rel)).to eq(true)
      end
    end
  end
end
