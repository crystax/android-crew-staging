require 'fileutils'
require 'digest'
require_relative 'exceptions.rb'
require_relative 'formula.rb'
require_relative 'properties.rb'
require_relative 'release.rb'
require_relative 'build.rb'
require_relative 'build_options.rb'


class BasePackage < Formula

  namespace :target

  include Properties

  def initialize(path)
    super path

    # mark installed releases and sources
    releases.each { |r| r.update get_properties(release_directory(r)) }

    @pre_build_result = nil
  end

  def release_directory(release)
    File.join(Global::SERVICE_DIR, file_name, release.version)
  end

  def cache_file(release)
    File.join(Global::PKG_CACHE_DIR, archive_filename(release, ''))
  end

  def source_installed?(release)
    true
  end

  def update_shasum(release)
    s = File.read(path).sub(/sha256:\s+'\h+'/, "sha256: '#{release.shasum}'")
    File.open(path, 'w') { |f| f.puts s }
  end

  def archive_filename(release, _)
    "#{file_name}-#{release}.tar.xz"
  end

  private

  def sha256_sum(release)
    release.shasum(:android)
  end

  def build_base_dir
    "#{Build::BASE_TARGET_DIR}/#{file_name}"
  end

  def build_log_file
    "#{build_base_dir}/build.log"
  end
end
