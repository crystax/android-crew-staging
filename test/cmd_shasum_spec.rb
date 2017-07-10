# must be first file included
require_relative 'spec_helper.rb'

require_relative '../library/platform.rb'


describe "crew shasum" do
  before(:all) do
    ndk_init
  end

  before(:each) do
    clean_hold
    clean_cache
    repository_init
    repository_clone
  end

  context 'with --check option' do

    context 'with empty package cache' do
      it 'says that all archives for the current platfrom are not found' do
        lines = Crew::Test::ALL_TOOLS.map { |e| "host/#{e.name} .* #{Global::PLATFORM_NAME}:.*#{Global::PKG_CACHE_DIR}/tools/#{e.filename}.*" }
        #File.open('/tmp/crew.log', 'a') { |f| f.puts "DEBUG: lines: #{lines}" }
        crew 'shasum', '--check'
        # expect(out).to eq('')
        got = out.split("\n")
        expect(:ok).to eq(result)
        expect(got.size).to eq(lines.size)
        got.each_with_index { |g, i| expect(g).to match(lines[i]) }
      end
    end

    context 'with empty package cache and with --platforms option' do
      it 'says that all archives for all platforms are not found' do
        lines = Crew::Test::ALL_TOOLS.map { |e| Platform::NAMES.map { |p| "host/#{e.name} .* #{p}:.*#{Global::PKG_CACHE_DIR}/tools/#{e.filename}.*" } }.flatten
        #File.open('/tmp/crew.log', 'a') { |f| f.puts "DEBUG: lines: #{lines}" }
        crew 'shasum', '--check', "--platforms=#{Platform::NAMES.join(',')}"
        # expect(out).to eq('')
        got = out.split("\n")
        expect(result).to eq(:ok)
        expect(got.size).to eq(lines.size)
        got.each_with_index { |g, i| expect(g).to match(lines[i]) }
      end
    end

    context 'with full cache, with absent sums file and with util name' do
      it 'says that sum is BAD' do
        rel = Crew::Test::UTILS_RELEASES['curl'][0]
        pkg_cache_add_file_in :host, 'curl', rel
        crew 'shasum', '--check', 'curl'
        expect(out.strip).to eq("host/curl #{rel} #{Global::PLATFORM_NAME}: BAD")
      end
    end

    context 'with full cache, with updated sums file and with util name' do
      it 'says that sum is OK' do
        rel = Crew::Test::UTILS_RELEASES['curl'][0]
        pkg_cache_add_file_in :host, 'curl', rel
        crew_checked 'shasum', '--update'
        crew 'shasum', '--check', 'curl'
        expect(out.strip).to eq("host/curl #{rel} #{Global::PLATFORM_NAME}: OK")
      end
    end

    context 'with full cache and with updated sums file' do
      it 'says that sum is OK for all archives for the current platform' do
        libone_rel = Release.new('1.0.0', 1)
        pkg_cache_add_all_tools_in
        copy_formulas 'libone.rb'
        pkg_cache_add_file_in :target, 'libone', libone_rel
        crew_checked 'shasum', '--update'
        crew_checked 'install', 'libone'
        crew 'shasum', '--check'
        lines = Crew::Test::ALL_TOOLS.map { |e| "host/#{e.name} .* #{Global::PLATFORM_NAME}: OK" } + ["target/libone #{libone_rel}: OK"]
        #expect(out).to eq('')
        got = out.split("\n")
        expect(result).to eq(:ok)
        expect(got.size).to eq(lines.size)
        got.each_with_index { |g, i| expect(g).to match(lines[i]) }
      end
    end
  end

  context 'with --update option' do

    context 'with empty cache and tool name' do
      it 'says that archive not found' do
      end
    end

    context 'with empty cache and package name' do
      it 'says that archive not found' do
      end
    end

    context 'with empty cache and no names' do
      it 'says that all archives for all installed formulas are not found' do
      end
    end

  end

  # context 'without options' do
  # end

  # context "without sums file" do



  #   context "with full cache and with util name and with --update option" do
  #     it "says that sum is updated" do
  #       rel = Crew::Test::UTILS_RELEASES['curl'][0]
  #       pkg_cache_add_util_in 'curl', rel
  #       crew 'shasum', '--update', 'curl'
  #       expect("host/curl #{rel} #{Global::PLATFORM_NAME}: updated").to eq(out.strip)
  #     end
  #   end

  # end

  # context "with existing sums file" do

  #   context "with full cache and with util name" do
  #     it "says that sum is BAD" do
  #       rel = Crew::Test::UTILS_RELEASES['curl'][0]
  #       pkg_cache_add_util_in 'curl', rel
  #       crew 'shasum', 'curl'
  #       expect("host/curl #{rel} #{Global::PLATFORM_NAME}: BAD").to eq(out.strip)
  #     end
  #   end
  # end
end
