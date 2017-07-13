require 'fileutils'
require 'digest'
require 'pathname'
require 'json'
require_relative 'spec_consts.rb'



if File.exists? Crew::Test::DATA_READY_FILE
  puts "Test data already prepared"
  puts "If you think this's an error, run make clean or make clean-test-data and rerun make"
  exit 0
end


ORIG_TOOLS_DIR   = Pathname.new(ENV['ORIG_TOOLS_DIR']).realpath.to_s
ORIG_NDK_DIR     = Pathname.new("#{ORIG_TOOLS_DIR}/../..").realpath.to_s
ORIG_FORMULA_DIR = Pathname.new('../formula/tools').realpath.to_s
PLATFORM         = File.basename(ORIG_TOOLS_DIR)
PLATFORM_SYM     = PLATFORM.gsub(/-/, '_').to_sym

tools_dir = "#{Crew::Test::NDK_DIR}/prebuilt/#{PLATFORM}"
utils_download_dir = "#{Crew::Test::DOCROOT_DIR}/tools"
packages_download_dir = "#{Crew::Test::DOCROOT_DIR}/packages"
FileUtils.mkdir_p [tools_dir, utils_download_dir, packages_download_dir]

DATA_DIR           = Pathname.new(Crew::Test::DATA_DIR).realpath.to_s
NDK_DIR            = Pathname.new(Crew::Test::NDK_DIR).realpath.to_s
TOOLS_DIR          = Pathname.new(tools_dir).realpath.to_s
UTILS_DOWNLOAD_DIR = Pathname.new(utils_download_dir).realpath.to_s


# copy utils from NDK dir to tests directory structure
FileUtils.cp_r Dir["#{ORIG_TOOLS_DIR}/*"], TOOLS_DIR
FileUtils.cp_r "#{ORIG_NDK_DIR}/.crew", Crew::Test::NDK_DIR
FileUtils.cp Dir["#{Crew::Test::DATA_DIR}/*.tar.xz"], packages_download_dir
FileUtils.rm_rf "#{TOOLS_DIR}/build_dependencies"

require_relative '../library/release.rb'
require_relative '../library/utils.rb'
require_relative '../library/utility.rb'
require_relative '../library/properties.rb'

include Properties


RELEASE_REGEXP = /^[[:space:]]*release[[:space:]]+version/
END_REGEXP = /^end/

def replace_releases(formula, releases)
  lines = []
  File.foreach(formula) do |l|
    case l
    when RELEASE_REGEXP
      # skip old release lines
      nil
    when END_REGEXP
      # output new release lines before line with 'end'
      releases.each do |r|
        lines << "  release version: '#{r.version}', crystax_version: #{r.crystax_version}"
      end
      lines << ''
      lines << l
    else
      # copy lines
      lines << l
    end
  end

  lines
end

def installed_release(utility_name)
  versions = Dir["#{File.join(ORIG_NDK_DIR, '.crew', utility_name, PLATFORM)}/*"]

  raise "#{utility_name} not installed" if versions.empty?
  raise "more than one version of #{utility_name} installed: #{versions}" if versions.size > 1

  ver = File.basename(versions[0])
  crystax_ver = get_properties(versions[0])[:installed_crystax_version]

  Release.new(ver, crystax_ver)
end

def create_archive(orig_release, release, util)
  package_dir = File.join('tmp', 'package')
  FileUtils.rm_rf package_dir
  FileUtils.mkdir_p package_dir
  package_dir = Pathname.new(package_dir).realpath.to_s

  # copy files
  FileUtils.cd(ORIG_NDK_DIR) do
    list_file = File.join('.crew', util, PLATFORM, orig_release.version, 'list')
    File.read(list_file).split("\n").each do |file|
      if File.directory?(file)
        FileUtils.mkdir_p File.join(package_dir, file)
      else
        target_dir = File.join(package_dir, File.dirname(file))
        FileUtils.mkdir_p target_dir
        FileUtils.cp file, target_dir
      end
    end
    FileUtils.cp list_file, package_dir
  end

  # make archive
  archive_path = File.join(UTILS_DOWNLOAD_DIR, "#{util}-#{release}-#{PLATFORM}.#{Global::ARCH_EXT}")
  FileUtils.mkdir_p File.dirname(archive_path)
  FileUtils.cd(package_dir) do
    args = ['-Jcf', archive_path, '.']
    Utils.run_command(File.join(ORIG_TOOLS_DIR, 'bin', 'bsdtar'), *args)
  end

  # cleanup
  FileUtils.rm_rf package_dir
end

#
# create test data for utilities
#

orig_releases = {}
Crew::Test::UTILS_FILES.each { |u| orig_releases[u] = installed_release(u) }

# create archives and formulas for curl
base = orig_releases['curl']
curl_releases = [base, Release.new(base.version, base.crystax_version + 2), Release.new(base.version + 'a', 1)].each do |r|
  create_archive(base, r, 'curl')
end
curl_formula = File.join(ORIG_FORMULA_DIR, 'curl.rb')
File.open(File.join(DATA_DIR, 'curl-1.rb'), 'w') { |f| f.puts replace_releases(curl_formula, curl_releases.slice(0, 1)) }
File.open(File.join(DATA_DIR, 'curl-2.rb'), 'w') { |f| f.puts replace_releases(curl_formula, curl_releases.slice(1, 1)) }
File.open(File.join(DATA_DIR, 'curl-3.rb'), 'w') { |f| f.puts replace_releases(curl_formula, curl_releases.slice(1, 2)) }

# create archives and formulas for libarchive
base = orig_releases['libarchive']
libarchive_releases = [base, Release.new(base.version + 'a', 1)].each do |r|
  create_archive(base, r, 'libarchive')
end
libarchive_formula = File.join(ORIG_FORMULA_DIR, 'libarchive.rb')
File.open(File.join(DATA_DIR, 'libarchive-1.rb'), 'w') { |f| f.puts replace_releases(libarchive_formula, libarchive_releases.slice(0, 1)) }
File.open(File.join(DATA_DIR, 'libarchive-2.rb'), 'w') { |f| f.puts replace_releases(libarchive_formula, libarchive_releases.slice(0, 2)) }

# create archives and formulas for ruby
base = orig_releases['ruby']
ruby_releases = [base, Release.new(base.version + 'a', 1)].each do |r|
  create_archive(base, r, 'ruby')
end
ruby_formula = File.join(ORIG_FORMULA_DIR, 'ruby.rb')
File.open(File.join(DATA_DIR, 'ruby-1.rb'), 'w') { |f| f.puts replace_releases(ruby_formula, ruby_releases.slice(0, 1)) }
File.open(File.join(DATA_DIR, 'ruby-2.rb'), 'w') { |f| f.puts replace_releases(ruby_formula, ruby_releases.slice(0, 2)) }

# create mock archives for all other tools, like make, yasm , etc
Crew::Test::ALL_TOOLS.select { |t| not Crew::Test::UTILS_FILES.include?(t.filename) }.map do |t|
  rel = installed_release(t.filename)
  create_archive(rel, rel, t.filename)
  File.open("#{DATA_DIR}/#{t.filename}-1.rb", 'w') { |f| f.puts replace_releases("#{ORIG_FORMULA_DIR}/#{t.filename}.rb", [rel]) }
end

# generate ruby source file with releases info
curl_releases_str       = curl_releases.map       { |r| "Release.new(\'#{r.version}\', #{r.crystax_version})" }.join(', ')
libarchive_releases_str = libarchive_releases.map { |r| "Release.new(\'#{r.version}\', #{r.crystax_version})" }.join(', ')
ruby_releases_str       = ruby_releases.map       { |r| "Release.new(\'#{r.version}\', #{r.crystax_version})" }.join(', ')

RELEASES_DATA = <<-EOS
# Automatocally generated! Do not edit.

module Crew

  module Test

    UTILS_RELEASES = {
      'curl'       => [ #{curl_releases_str} ],
      'libarchive' => [ #{libarchive_releases_str} ],
      'ruby'       => [ #{ruby_releases_str} ]
    }
  end
end
EOS

File.open(Crew::Test::UTILS_RELEASES_FILE, 'w') { |f| f.write(RELEASES_DATA) }

FileUtils.mv Crew::Test::NDK_DIR, Crew::Test::NDK_COPY_DIR

FileUtils.touch Crew::Test::DATA_READY_FILE
