require 'fileutils'
require 'digest'
require 'pathname'
require 'json'
require_relative 'spec_consts.rb'



if File.exists? Crew_test::DATA_READY_FILE
  puts "Test data already prepared"
  puts "If you think this's an error, run make clean or make clean-test-data and rerun make"
  exit 0
end

tools_dir          = ENV['CREW_TOOLS_DIR']
PLATFORM           = File.basename(tools_dir)
PLATFORM_SYM       = PLATFORM.gsub(/-/, '_').to_sym
utils_download_dir = File.join(Crew_test::DOCROOT_DIR, 'tools')
orig_ndk_dir       = ENV['ORIG_NDK_DIR']
orig_tools_dir     = File.join(orig_ndk_dir, 'prebuilt', PLATFORM)

# copy utils from NDK dir to tests directory structure
FileUtils.mkdir_p [tools_dir, utils_download_dir]
FileUtils.cp_r Dir["#{orig_tools_dir}/*"], tools_dir
FileUtils.cp_r "#{orig_ndk_dir}/.crew", Crew_test::NDK_DIR
FileUtils.rm_rf "#{tools_dir}/build_dependencies"
FileUtils.cp_r Crew_test::NDK_DIR, Crew_test::NDK_COPY_DIR

require_relative '../library/release.rb'
require_relative '../library/utils.rb'
require_relative '../library/utility.rb'
require_relative '../library/properties.rb'

include Properties


ORIG_NDK_DIR       = Pathname.new(orig_ndk_dir).realpath.to_s
ORIG_TOOLS_DIR     = Pathname.new(orig_tools_dir).realpath.to_s
ORIG_FORMULA_DIR   = Pathname.new(File.join('..', 'formula', 'tools')).realpath.to_s
TOOLS_DIR          = Pathname.new(tools_dir).realpath.to_s
UTILS_DOWNLOAD_DIR = Pathname.new(utils_download_dir).realpath.to_s
DATA_DIR           = Pathname.new(Crew_test::DATA_DIR).realpath.to_s
NDK_DIR            = Pathname.new(Crew_test::NDK_DIR).realpath.to_s

RELEASE_REGEXP = /^[[:space:]]*release[[:space:]]+version/
RELEASE_END_REGEXP = /^[[:space:]]+}[[:space:]]*$/
END_REGEXP = /^end/

def replace_releases(formula, releases)
  lines = []
  state = :copy
  File.foreach(formula) do |l|
    fname = File.basename(formula)
    case l
    when RELEASE_REGEXP
      case state
      when :copy
        state = :skip
      else
        raise "error in #{fname}: in state '#{state}' unexpected line: #{l}"
      end
    when RELEASE_END_REGEXP
      case state
      when :skip
        state = :copy
      else
        raise "error in #{fname}: in state '#{state}' unexpected line: #{l}"
      end
    when END_REGEXP
      case state
      when :copy
        releases.each do |r|
          lines << "  release version: '#{r.version}', crystax_version: #{r.crystax_version}, sha256: { #{PLATFORM_SYM}: '#{r.shasum(PLATFORM_SYM)}' }"
        end
        lines << ''
        lines << l
      else
        raise "error in #{fname}: in state #{state} unexpected line: #{l}"
      end
    else
        lines << l if state == :copy
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
  archive_path = File.join(UTILS_DOWNLOAD_DIR, util, "#{util}-#{release}-#{PLATFORM}.#{Global::ARCH_EXT}")
  FileUtils.mkdir_p File.dirname(archive_path)
  FileUtils.cd(package_dir) do
    args = ['-Jcf', archive_path, '.']
    Utils.run_command(File.join(ORIG_TOOLS_DIR, 'bin', 'bsdtar'), *args)
  end

  # cleanup
  FileUtils.rm_rf package_dir

  # calculate and return sha256 sum
  Digest::SHA256.hexdigest(File.read(archive_path, mode: "rb"))
end

#
# create test data for utilities
#

orig_releases = {}
Crew_test::UTILS.each { |u| orig_releases[u] = installed_release(u) }

# create archives and formulas for curl
base = orig_releases['curl']
curl_releases = [base, Release.new(base.version, base.crystax_version + 2), Release.new(base.version + 'a', 1)].map do |r|
  r.shasum = { PLATFORM_SYM => create_archive(base, r, 'curl') }
  r
end
curl_formula = File.join(ORIG_FORMULA_DIR, 'curl.rb')
File.open(File.join(DATA_DIR, 'curl-1.rb'), 'w') { |f| f.puts replace_releases(curl_formula, curl_releases.slice(0, 1)) }
File.open(File.join(DATA_DIR, 'curl-2.rb'), 'w') { |f| f.puts replace_releases(curl_formula, curl_releases.slice(1, 1)) }
File.open(File.join(DATA_DIR, 'curl-3.rb'), 'w') { |f| f.puts replace_releases(curl_formula, curl_releases.slice(1, 2)) }

# create archives and formulas for libarchive
base = orig_releases['libarchive']
libarchive_releases = [base, Release.new(base.version + 'a', 1)].map do |r|
  r.shasum = { PLATFORM_SYM => create_archive(base, r, 'libarchive') }
  r
end
libarchive_formula = File.join(ORIG_FORMULA_DIR, 'libarchive.rb')
File.open(File.join(DATA_DIR, 'libarchive-1.rb'), 'w') { |f| f.puts replace_releases(libarchive_formula, libarchive_releases.slice(0, 1)) }
File.open(File.join(DATA_DIR, 'libarchive-2.rb'), 'w') { |f| f.puts replace_releases(libarchive_formula, libarchive_releases.slice(0, 2)) }

# create archives and formulas for ruby
base = orig_releases['ruby']
ruby_releases = [base, Release.new(base.version + 'a', 1)].map do |r|
  r.shasum = { PLATFORM_SYM => create_archive(base, r, 'ruby') }
  r
end
ruby_formula = File.join(ORIG_FORMULA_DIR, 'ruby.rb')
File.open(File.join(DATA_DIR, 'ruby-1.rb'), 'w') { |f| f.puts replace_releases(ruby_formula, ruby_releases.slice(0, 1)) }
File.open(File.join(DATA_DIR, 'ruby-2.rb'), 'w') { |f| f.puts replace_releases(ruby_formula, ruby_releases.slice(0, 2)) }

# generate ruby source file with releases info
curl_releases_str       = curl_releases.map       { |r| "Release.new(\'#{r.version}\', #{r.crystax_version})" }.join(', ')
libarchive_releases_str = libarchive_releases.map { |r| "Release.new(\'#{r.version}\', #{r.crystax_version})" }.join(', ')
ruby_releases_str       = ruby_releases.map       { |r| "Release.new(\'#{r.version}\', #{r.crystax_version})" }.join(', ')

RELEASES_DATA = <<-EOS
# Automatocally generated! Do not edit.

module Crew_test

  UTILS_RELEASES = {
    'curl'       => [ #{curl_releases_str} ],
    'libarchive' => [ #{libarchive_releases_str} ],
    'ruby'       => [ #{ruby_releases_str} ]
  }
end

EOS

File.open(Crew_test::UTILS_RELEASES_FILE, 'w') { |f| f.write(RELEASES_DATA) }

FileUtils.touch Crew_test::DATA_READY_FILE
