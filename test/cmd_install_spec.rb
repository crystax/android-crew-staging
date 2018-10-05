# must be first file included
require_relative 'spec_helper.rb'

require_relative '../library/github.rb'


describe "crew install" do

  def install_message(name, url, file)
    ["calculating dependencies for #{name}:",
     "dependencies to install:",
     "downloading #{url}",
     "checking integrity of the archive file #{file}",
     "unpacking archive"
    ]
  end

  before(:all) do
    environment_init
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

  context "existing formula with bad sha256 sum of the downloaded file" do
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

  context "existing formula with one release and no dependencies" do

    context "specifing only name" do
      it "outputs info about installing existing release" do
        rel = pkg_cache_add_package_with_formula('libone', delete: true)
        file = package_archive_name('libone', rel)
        url = "#{Global::DOWNLOAD_BASE}/packages/#{file}"
        crew 'install', 'libone'
        expect(result).to eq(:ok)
        expect(out.split("\n").map(&:strip)).to eq(install_message('libone', url, file))
        expect(pkg_cache_has_package?('libone', rel)).to eq(true)
      end
    end

    context "specifing name and version" do
      it "outputs info about installing existing release" do
        rel = pkg_cache_add_package_with_formula('libone', delete: true)
        file = package_archive_name('libone', rel)
        url = "#{Global::DOWNLOAD_BASE}/packages/#{file}"
        crew 'install', 'libone:1.0.0'
        expect(result).to eq(:ok)
        expect(out.split("\n").map(&:strip)).to eq(install_message('libone', url, file))
        expect(pkg_cache_has_package?('libone', rel)).to eq(true)
      end
    end

    context "specifing full release info" do
      it "outputs info about installing existing release" do
        rel = pkg_cache_add_package_with_formula('libone', delete: true)
        file = package_archive_name('libone', rel)
        url = "#{Global::DOWNLOAD_BASE}/packages/#{file}"
        crew 'install', 'libone:1.0.0:1'
        expect(result).to eq(:ok)
        expect(out.split("\n").map(&:strip)).to eq(install_message('libone', url, file))
        expect(pkg_cache_has_package?('libone', rel)).to eq(true)
      end
    end

    context "specifing non existing version" do
      it "outputs info about installing existing release" do
        copy_package_formulas 'libone.rb'
        crew 'install', 'libone:2.0.0'
        expect(exitstatus).to_not be_zero
        expect(err.split("\n")[0]).to eq('error: libone has no release with version 2.0.0')
      end
    end

    context "from the cache" do
      it "outputs info about using cached file" do
        rel = pkg_cache_add_package_with_formula('libone')
        file = package_archive_name('libone', rel)
        crew 'install', 'libone'
        expect(result).to eq(:ok)
        expect(out.split("\n").map(&:strip)).to eq(["calculating dependencies for libone:",
                                                    "dependencies to install:",
                                                    "using cached file #{file}",
                                                    "checking integrity of the archive file #{file}",
                                                    "unpacking archive"
                                                   ])
        expect(pkg_cache_has_package?('libone', rel)).to eq(true)
      end
    end
  end

  context "existing formula with two versions and one dependency" do

    context 'dependency is not installed' do
      it "outputs info about installing dependency and the latest version" do
        libone_rel = pkg_cache_add_package_with_formula('libone', delete: true)
        libtwo_rel = pkg_cache_add_package_with_formula('libtwo', delete: true)
        depfile = package_archive_name('libone', libone_rel)
        depurl = "#{Global::DOWNLOAD_BASE}/packages/#{depfile}"
        resfile = package_archive_name('libtwo', libtwo_rel)
        resurl = "#{Global::DOWNLOAD_BASE}/packages/#{resfile}"
        crew 'install', 'libtwo'
        expect(result).to eq(:ok)
        expect(out.split("\n").map(&:strip)).to eq(["calculating dependencies for libtwo:",
                                                    "dependencies to install: libone",
                                                    "installing dependencies for libtwo:",
                                                    "downloading #{depurl}",
                                                    "checking integrity of the archive file #{depfile}",
                                                    "unpacking archive",
                                                    "",
                                                    "downloading #{resurl}",
                                                    "checking integrity of the archive file #{resfile}",
                                                    "unpacking archive"
                                                   ])
        expect(pkg_cache_has_package?('libone', libone_rel)).to eq(true)
        expect(pkg_cache_has_package?('libtwo', libtwo_rel)).to eq(true)
      end
    end

    context 'dependency is installed' do
      it "outputs info about installing the latest version" do
        pkg_cache_add_package_with_formula('libone', delete: true)
        crew_checked 'install', 'libone'
        rel = pkg_cache_add_package_with_formula('libtwo', delete: true)
        file = package_archive_name('libtwo', rel)
        url = "#{Global::DOWNLOAD_BASE}/packages/#{file}"
        crew 'install', 'libtwo'
        expect(result).to eq(:ok)
        expect(out.split("\n").map(&:strip)).to eq(install_message('libtwo', url, file))
        expect(pkg_cache_has_package?('libtwo', rel)).to eq(true)
      end
    end
  end

  context "specific release of the existing formula with three releases and two dependencies" do
    it "outputs info about installing dependencies and the specified release" do
      libone_rel   = pkg_cache_add_package_with_formula('libone',   delete: true)
      libtwo_rel   = pkg_cache_add_package_with_formula('libtwo',   delete: true, release: Release.new('2.2.0', 1))
      libthree_rel = pkg_cache_add_package_with_formula('libthree', delete: true, release: Release.new('2.2.2', 1))
      depfile1 = package_archive_name('libone',   libone_rel)
      depfile2 = package_archive_name('libtwo',   libtwo_rel)
      resfile  = package_archive_name('libthree', libthree_rel)
      depurl1 = "#{Global::DOWNLOAD_BASE}/packages/#{depfile1}"
      depurl2 = "#{Global::DOWNLOAD_BASE}/packages/#{depfile2}"
      resurl  = "#{Global::DOWNLOAD_BASE}/packages/#{resfile}"
      crew 'install', 'libthree:2.2.2:1'
      expect(result).to eq(:ok)
      expect(out.split("\n").map(&:strip)).to eq(["calculating dependencies for libthree:",
                                                  "dependencies to install: libone, libtwo",
                                                  "installing dependencies for libthree:",
                                                  "downloading #{depurl1}",
                                                  "checking integrity of the archive file #{depfile1}",
                                                  "unpacking archive",
                                                  "downloading #{depurl2}",
                                                  "checking integrity of the archive file #{depfile2}",
                                                  "unpacking archive",
                                                  "",
                                                  "downloading #{resurl}",
                                                  "checking integrity of the archive file #{resfile}",
                                                  "unpacking archive"
                                                 ])
      expect(pkg_cache_has_package?('libone',   libone_rel)).to   eq(true)
      expect(pkg_cache_has_package?('libtwo',   libtwo_rel)).to   eq(true)
      expect(pkg_cache_has_package?('libthree', libthree_rel)).to eq(true)
    end
  end

  context "existing formula with four versions, 11 releases, specifying only name" do
    it "outputs info about installing latest release" do
      rel = pkg_cache_add_package_with_formula('libfour', update: true, delete: true)
      file = package_archive_name('libfour', rel)
      url = "#{Global::DOWNLOAD_BASE}/packages/#{file}"
      crew 'install', 'libfour'
      expect(result).to eq(:ok)
      expect(out.split("\n").map(&:strip)).to eq(install_message('libfour', url, file))
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
      expect(out.split("\n").map(&:strip)).to eq(install_message('libfour', url, file))
      expect(pkg_cache_has_package?('libfour', rel)).to eq(true)
    end
  end

  context 'extisting formula with one dependecy and specific dependency version' do

    context 'with no dependency installed' do
      it 'outputs info about installing required dependency and target package' do
        dep_rel = pkg_cache_add_package_with_formula('libfour', delete: true, release: Release.new('1.1.1', 1))
        dep_file = package_archive_name('libfour', dep_rel)
        dep_url = "#{Global::DOWNLOAD_BASE}/packages/#{dep_file}"
        rel = pkg_cache_add_package_with_formula('libfive', delete: true)
        file = package_archive_name('libfive', rel)
        url = "#{Global::DOWNLOAD_BASE}/packages/#{file}"
        crew 'install', 'libfive'
        expect(result).to eq(:ok)
        expect(out.split("\n").map(&:strip)).to eq(["calculating dependencies for libfive:",
                                                    "dependencies to install: libfour",
                                                    "installing dependencies for libfive:",
                                                    "downloading #{dep_url}",
                                                    "checking integrity of the archive file #{dep_file}",
                                                    "unpacking archive",
                                                    "",
                                                    "downloading #{url}",
                                                    "checking integrity of the archive file #{file}",
                                                    "unpacking archive"
                                                   ])
        expect(pkg_cache_has_package?('libfive', rel)).to eq(true)
      end
    end

    context 'with incorrrect verion installed' do
      it 'outputs info about installing required dependency and target package' do
        copy_package_formulas 'libfour.rb'
        pkg_cache_add_package 'libfour', Release.new('1.1.1', 1)
        pkg_cache_add_package 'libfour', Release.new('4.4.4', 4)
        crew_checked 'install', 'libfour:4.4.4'
        dep_file = package_archive_name('libfour', Release.new('1.1.1', 1))

        rel = pkg_cache_add_package_with_formula('libfive', delete: true)
        file = package_archive_name('libfive', rel)
        url = "#{Global::DOWNLOAD_BASE}/packages/#{file}"
        crew 'install', 'libfive'
        expect(result).to eq(:ok)
        expect(out.split("\n").map(&:strip)).to eq(["calculating dependencies for libfive:",
                                                    "dependencies to install: libfour",
                                                    "installing dependencies for libfive:",
                                                    "using cached file #{dep_file}",
                                                    "checking integrity of the archive file #{dep_file}",
                                                    "unpacking archive",
                                                    "",
                                                    "downloading #{url}",
                                                    "checking integrity of the archive file #{file}",
                                                    "unpacking archive"
                                                   ])
        expect(pkg_cache_has_package?('libfive', rel)).to eq(true)
      end
    end

    context 'with correct version installed' do
      it 'outputs info about installing target package' do
        copy_package_formulas 'libfour.rb'
        pkg_cache_add_package 'libfour', Release.new('1.1.1', 1)
        crew_checked 'install', 'libfour:1.1.1'

        rel = pkg_cache_add_package_with_formula('libfive', delete: true)
        file = package_archive_name('libfive', rel)
        url = "#{Global::DOWNLOAD_BASE}/packages/#{file}"
        crew 'install', 'libfive'
        expect(result).to eq(:ok)
        expect(out.split("\n").map(&:strip)).to eq(install_message('libfive', url, file))
        expect(pkg_cache_has_package?('libfive', rel)).to eq(true)
      end
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
        expect(out.split("\n").map(&:strip)).to eq(install_message('test_package', url, file))
        expect(pkg_cache_has_package?('test_package', rel)).to eq(true)
      end
    end

    context 'test tool from release assets' do
      it 'outputs info about installing test_tool 1.0.0:1' do
        rel = pkg_cache_add_tool_with_formula('test_tool', release: Release.new('1.0.0', 1), update: true, delete: true)
        file = tool_archive_name('test_tool', rel)
        ENV['CREW_DOWNLOAD_BASE'] = nil
        set_origin_url GitHub::STAGING_HTTPS_URL
        crew_checked 'env',  '--download-base'
        url = "#{out.strip}/tools.#{file}"
        crew 'install', 'test_tool:1.0.0'
        expect(result).to eq(:ok)
        expect(out.split("\n").map(&:strip)).to eq(install_message('test_tool', url, file))
        expect(pkg_cache_has_tool?('test_tool', rel)).to eq(true)
      end
    end
  end
end
