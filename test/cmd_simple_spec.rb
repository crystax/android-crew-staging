# must be first file included
require_relative 'spec_helper.rb'

require_relative '../library/global.rb'
require_relative '../library/cmd/help.rb'

describe "simple crew commands" do
  before(:all) do
    ndk_init
  end

  before(:each) do
    environment_init
    repository_init
    repository_clone
  end

  context "crew" do
    it "outputs help info" do
      crew '-b'
      expect(result).to eq(:ok)
      expect(out).to eq(CREW_HELP)
    end
  end

  context "crew help" do
    it "outputs help info" do
      crew 'help'
      expect(result).to eq(:ok)
      expect(out).to eq(CREW_HELP)
    end
  end

  context "crew version" do

    context "with argument" do
      it "outputs error message" do
        crew 'version', 'bar'
        expect(exitstatus).to_not be_zero
        expect(err.split("\n")[0]).to eq('error: this command requires no arguments')
      end
    end

    context "without argument" do
      it "outputs version info" do
        crew 'version'
        expect(out.chomp).to eq(Global::VERSION)
        expect(exitstatus).to be_zero
      end
    end
  end

  context "crew env" do

    context 'with default environment' do

      context 'without arguments' do
        it "outputs crew's default working environment" do
          crew 'env'
          expect(result).to eq(:ok)
          expect(out.split("\n")).to eq(["DOWNLOAD_BASE:  #{Global::DOWNLOAD_BASE}",
                                         "PKG_CACHE_BASE: #{Global::PKG_CACHE_BASE}",
                                         "SRC_CACHE_BASE: #{Global::SRC_CACHE_BASE}",
                                         "BASE_DIR:       #{Global::BASE_DIR}",
                                         "NDK_DIR:        #{Global::NDK_DIR}",
                                         "TOOLS_DIR:      #{Global::TOOLS_DIR}",
                                         "BASE_BUILD_DIR: #{Build::BASE_BUILD_DIR}"
                                        ])
        end
      end

      context "with --download-base option" do
        it "outputs crew's download base string" do
          crew 'env --download-base'
          expect(result).to eq(:ok)
          expect(out.strip).to eq(Global::DOWNLOAD_BASE)
        end
      end

      context "with --download-base option and origin set to ssh github url" do
        it "outputs crew's download base string" do
          ENV['CREW_DOWNLOAD_BASE'] = nil
          set_origin_url GitHub::STAGING_SSH_URL
          crew 'env --download-base'
          expect(result).to eq(:ok)
          expect(out.strip).to eq(GitHub::STAGING_DONWLOAD_BASE)
        end
      end

      context "with --download-base option and origin set to https github url" do
        it "outputs crew's download base string" do
          ENV['CREW_DOWNLOAD_BASE'] = nil
          set_origin_url GitHub::STAGING_HTTPS_URL
          crew 'env --download-base'
          expect(result).to eq(:ok)
          expect(out.strip).to eq(GitHub::STAGING_DONWLOAD_BASE)
        end
      end

      context "crew env --base-dir" do
        it "outputs crew's base directory" do
          crew 'env --base-dir'
          expect(result).to eq(:ok)
          expect(out.strip).to eq(Global::BASE_DIR)
        end
      end

      context "crew env --tools-dir" do
        it "outputs NDK tools directory" do
          crew 'env --tools-dir'
          expect(result).to eq(:ok)
          expect(out.strip).to eq(Global::TOOLS_DIR)
        end
      end

      context "crew env --pkg-cache-dir" do
        it "outputs crew's packages cache directory" do
          crew 'env --pkg-cache-dir'
          expect(result).to eq(:ok)
          expect(out.strip).to eq(Global::PKG_CACHE_DIR)
        end
      end

      context "crew env --src-cache-dir" do
        it "outputs crew's packages cache directory" do
          crew 'env --src-cache-dir'
          expect(result).to eq(:ok)
          expect(out.strip).to eq(Global::SRC_CACHE_DIR)
        end
      end

      context "crew env --base-build-dir" do
        it "outputs crew's base build directory" do
          crew 'env --src-cache-dir'
          expect(result).to eq(:ok)
          expect(out.strip).to eq(Global::SRC_CACHE_DIR)
        end
      end
    end

    # todo: add more test, set environment variables to nil, '', and different strings
    # context 'with modified environment' do
    # end
  end
end
