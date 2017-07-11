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

      context 'without options and argument' do
        it 'says that all archives for the current platfrom are not found' do
          lines = Crew::Test::ALL_TOOLS.map { |e| "host/#{e.name} .* #{Global::PLATFORM_NAME}:.*#{Global::PKG_CACHE_DIR}/tools/#{e.filename}.*" }
          crew 'shasum', '--check'
          got = out.split("\n")
          expect(:ok).to eq(result)
          expect(got.size).to eq(lines.size)
          got.each_with_index { |g, i| expect(g).to match(lines[i]) }
        end
      end

      context 'with --platforms option' do
        it 'says that all archives for all platforms are not found' do
          lines = Crew::Test::ALL_TOOLS.map { |e| Platform::NAMES.map { |p| "host/#{e.name} .* #{p}:.*#{Global::PKG_CACHE_DIR}/tools/#{e.filename}.*" } }.flatten
          crew 'shasum', '--check', "--platforms=#{Platform::NAMES.join(',')}"
          got = out.split("\n")
          expect(result).to eq(:ok)
          expect(got.size).to eq(lines.size)
          got.each_with_index { |g, i| expect(g).to match(lines[i]) }
        end
      end
    end

    context 'with full package cache' do

      context 'with absent sums file' do

        context 'with util name' do
          it 'says that sum is BAD' do
            rel = pkg_cache_add_tool 'curl'
            crew 'shasum', '--check', 'curl'
            expect(out.strip).to eq("host/curl #{rel} #{Global::PLATFORM_NAME}: BAD")
          end
        end

        context 'with package name' do
          it 'says that sum is BAD' do
            rel = pkg_cache_add_package_with_formula 'libone'
            crew 'shasum', '--check', 'libone'
            expect(out.strip).to eq("target/libone #{rel}: BAD")
          end
        end

        context 'without names' do
          it 'says that sum is BAD for all archives in the cache' do
            pkg_cache_add_all_tools_in
            rel = pkg_cache_add_package_with_formula 'libone'
            crew 'shasum', '--check'
            lines = Crew::Test::ALL_TOOLS.map { |e| "host/#{e.name} .* #{Global::PLATFORM_NAME}: BAD" } + ["target/libone #{rel}: BAD"]
            got = out.split("\n")
            expect(result).to eq(:ok)
            expect(got.size).to eq(lines.size)
            got.each_with_index { |g, i| expect(g).to match(lines[i]) }
          end
        end
      end

      context 'with updated sums file and good archives' do

        context 'with util name' do
          it 'says that sum is OK' do
            rel = pkg_cache_add_tool 'curl'
            crew_checked 'shasum', '--update'
            crew 'shasum', '--check', 'curl'
            expect(out.strip).to eq("host/curl #{rel} #{Global::PLATFORM_NAME}: OK")
          end
        end

        context 'with package name' do
          it 'says that sum is OK' do
            rel = pkg_cache_add_package_with_formula 'libone'
            crew_checked 'shasum', '--update'
            crew 'shasum', '--check', 'libone'
            expect(out.strip).to eq("target/libone #{rel}: OK")
          end
        end

        context 'without names' do
          it 'says that sum is OK for all archives for the current platform' do
            pkg_cache_add_all_tools_in
            rel = pkg_cache_add_package_with_formula 'libone'
            crew_checked 'shasum', '--update'
            crew 'shasum', '--check'
            lines = Crew::Test::ALL_TOOLS.map { |e| "host/#{e.name} .* #{Global::PLATFORM_NAME}: OK" } + ["target/libone #{rel}: OK"]
            got = out.split("\n")
            expect(result).to eq(:ok)
            expect(got.size).to eq(lines.size)
            got.each_with_index { |g, i| expect(g).to match(lines[i]) }
          end
        end
      end

      context 'with updated sums file and BAD archives' do

        context 'with util name' do
          it 'says that sum is BAD' do
            rel = pkg_cache_add_tool 'curl'
            crew_checked 'shasum', '--update'
            pkg_cache_corrupt_file :host, 'curl', rel
            crew 'shasum', '--check', 'curl'
            expect(out.strip).to eq("host/curl #{rel} #{Global::PLATFORM_NAME}: BAD")
          end
        end

        context 'with package name' do
          it 'says that sum is BAD' do
            rel = pkg_cache_add_package_with_formula 'libone'
            crew_checked 'shasum', '--update'
            pkg_cache_corrupt_file :target, 'libone', rel
            crew 'shasum', '--check', 'libone'
            expect(out.strip).to eq("target/libone #{rel}: BAD")
          end
        end

        context 'without names' do
          it 'says that sum is BAD for all bad archives in the cache' do
            pkg_cache_add_all_tools_in
            rel = pkg_cache_add_package_with_formula 'libone'
            crew_checked 'shasum', '--update'
            pkg_cache_corrupt_file :host, 'curl', Crew::Test::UTILS_RELEASES['curl'][0]
            pkg_cache_corrupt_file :target, 'libone', rel
            crew 'shasum', '--check'
            lines = Crew::Test::ALL_TOOLS.map do |e|
              res_str = (e.name == 'curl') ? 'BAD' : 'OK'
              "host/#{e.name} .* #{Global::PLATFORM_NAME}: #{res_str}"
            end
            lines << "target/libone #{rel}: BAD"
            got = out.split("\n")
            expect(result).to eq(:ok)
            expect(got.size).to eq(lines.size)
            got.each_with_index { |g, i| expect(g).to match(lines[i]) }
          end
        end
      end
    end
  end

  context 'with --update option' do

    context 'with empty package cache' do

      context 'with tool name' do
        it 'says that archive not found' do
          rel = Crew::Test::UTILS_RELEASES['curl'][0]
          crew 'shasum', '--update', 'curl'
          expect(out.strip).to match("host/curl #{rel} #{Global::PLATFORM_NAME}: archive not found: #{Global::PKG_CACHE_DIR}/tools/curl-#{rel}-.*")
        end
      end

      context 'with package name' do
        it 'says that archive not found' do
          copy_formulas 'libone.rb'
          rel = Release.new('1.0.0', 1)
          crew 'shasum', '--update', 'libone'
          expect(out.strip).to match("target/libone #{rel}: archive not found: #{Global::PKG_CACHE_DIR}/packages/libone-#{rel}.*")
        end
      end

      context 'with no names' do
        it 'says that all archives for all installed formulas are not found' do
          copy_formulas 'libone.rb'
          crew 'shasum', '--update'
          lines = Crew::Test::ALL_TOOLS.map { |e| "host/#{e.name} .* #{Global::PLATFORM_NAME}: archive not found: #{Global::PKG_CACHE_DIR}/tools/#{e.filename}-.*" }
          lines << "target/libone .*: archive not found: #{Global::PKG_CACHE_DIR}/packages/libone-.*"
          got = out.split("\n")
          expect(result).to eq(:ok)
          expect(got.size).to eq(lines.size)
          got.each_with_index { |g, i| expect(g).to match(lines[i]) }
        end
      end
    end

    context 'with full cache' do

      context 'with no sums' do

        context 'with tool name' do
          it 'says that sum is updated' do
            rel = pkg_cache_add_tool 'curl'
            crew 'shasum', '--update', 'curl'
            expect(out.strip).to eq("host/curl #{rel} #{Global::PLATFORM_NAME}: updated")
          end
        end

        context 'with package name' do
          it 'says that sum is updated' do
            rel = pkg_cache_add_package_with_formula 'libone'
            crew 'shasum', '--update', 'libone'
            expect(out.strip).to eq("target/libone #{rel}: updated")
          end
        end

        context 'with no names' do
          it 'says that sum is updated' do
            pkg_cache_add_all_tools_in
            rel = pkg_cache_add_package_with_formula 'libone'
            crew 'shasum', '--update'
            lines = Crew::Test::ALL_TOOLS.map { |e| "host/#{e.name} .* #{Global::PLATFORM_NAME}: updated" } + ["target/libone #{rel}: updated"]
            got = out.split("\n")
            expect(result).to eq(:ok)
            expect(got.size).to eq(lines.size)
            got.each_with_index { |g, i| expect(g).to match(lines[i]) }
          end
        end
      end

      context 'with correct sums' do

        context 'with tool name' do
          it 'says that sum is OK' do
            rel = pkg_cache_add_tool 'curl'
            crew_checked 'shasum', '--update', 'curl'
            crew 'shasum', '--update', 'curl'
            expect(out.strip).to eq("host/curl #{rel} #{Global::PLATFORM_NAME}: OK")
          end
        end

        context 'with package name' do
          it 'says that sum is OK' do
            rel = pkg_cache_add_package_with_formula 'libone'
            crew_checked 'shasum', '--update', 'libone'
            crew 'shasum', '--update', 'libone'
            expect(out.strip).to eq("target/libone #{rel}: OK")
          end
        end

        context 'with no names' do
          it 'says that sums are OK for all archives' do
            pkg_cache_add_all_tools_in
            rel = pkg_cache_add_package_with_formula 'libone'
            crew_checked 'shasum', '--update'
            crew 'shasum', '--update'
            lines = Crew::Test::ALL_TOOLS.map { |e| "host/#{e.name} .* #{Global::PLATFORM_NAME}: OK" } + ["target/libone #{rel}: OK"]
            got = out.split("\n")
            expect(result).to eq(:ok)
            expect(got.size).to eq(lines.size)
            got.each_with_index { |g, i| expect(g).to match(lines[i]) }
          end
        end
      end

      context 'with incorrect sums' do

        context 'with tool name' do
          it 'says that sum is updated' do
            rel = pkg_cache_add_tool 'curl'
            crew_checked 'shasum', '--update', 'curl'
            pkg_cache_corrupt_file :host, 'curl', rel
            crew 'shasum', '--update', 'curl'
            expect(out.strip).to eq("host/curl #{rel} #{Global::PLATFORM_NAME}: updated")
          end
        end

        context 'with package name' do
          it 'says that sum is updated' do
            rel = pkg_cache_add_package_with_formula 'libone'
            crew_checked 'shasum', '--update', 'libone'
            pkg_cache_corrupt_file :target, 'libone', rel
            crew 'shasum', '--update', 'libone'
            expect(out.strip).to eq("target/libone #{rel}: updated")
          end
        end

        context 'with no names' do
          it 'says that sums are updated for all archives with incorrect sums' do
            pkg_cache_add_all_tools_in
            rel = pkg_cache_add_package_with_formula 'libone'
            crew_checked 'shasum', '--update'
            pkg_cache_corrupt_file :host, 'curl', Crew::Test::UTILS_RELEASES['curl'][0]
            pkg_cache_corrupt_file :target, 'libone', rel
            crew 'shasum', '--update'
            lines = Crew::Test::ALL_TOOLS.map do |e|
              res_str = (e.name == 'curl') ? 'updated' : 'OK'
              "host/#{e.name} .* #{Global::PLATFORM_NAME}: #{res_str}"
            end
            lines << "target/libone #{rel}: updated"
            got = out.split("\n")
            expect(result).to eq(:ok)
            expect(got.size).to eq(lines.size)
            got.each_with_index { |g, i| expect(g).to match(lines[i]) }
          end
        end
      end
    end
  end

  context 'without options' do

    context 'with updated sum files, full cache and util and package name' do
      it 'works like --check option was specified' do
        curl_rel = pkg_cache_add_tool 'curl'
        libone_rel = pkg_cache_add_package_with_formula 'libone'
        crew_checked 'shasum', '--update'
        crew 'shasum', 'curl', 'libone'
        expect(out.split("\n")).to eq(["host/curl #{curl_rel} #{Global::PLATFORM_NAME}: OK",
                                       "target/libone #{libone_rel}: OK"
                                      ])
      end
    end

    context 'with updated sum files, full cache and no names' do
      it 'works like --check option was specified' do
        pkg_cache_add_all_tools_in
        rel = pkg_cache_add_package_with_formula 'libone'
        crew_checked 'shasum', '--update'
        crew 'shasum'
        lines = Crew::Test::ALL_TOOLS.map { |e| "host/#{e.name} .* #{Global::PLATFORM_NAME}: OK" } + ["target/libone #{rel}: OK"]
        got = out.split("\n")
        expect(result).to eq(:ok)
        expect(got.size).to eq(lines.size)
        got.each_with_index { |g, i| expect(g).to match(lines[i]) }
      end
    end
  end
end
