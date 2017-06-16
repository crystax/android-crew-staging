require_relative 'release.rb'
require_relative 'properties.rb'
require_relative 'formula.rb'


class TargetBase < Formula

  namespace :target

  include Properties

  def initialize(path)
    super path

    # mark installed releases and sources
    releases.each { |r| r.update get_properties(properties_directory(r)) }

    @pre_build_result = nil
  end

  def archive_filename(release, _ = nil)
    "#{file_name}-#{release}.tar.xz"
  end

  def cache_file(release, _ = nil)
    File.join(Global.pkg_cache_dir(self), archive_filename(release))
  end

  def sha256_sum(release, _ = nil)
    release.shasum(:android)
  end

  def update_shasum(release)
    archive = cache_file(release)
    release.shasum = Digest::SHA256.hexdigest(File.read(archive, mode: "rb"))

    regexp = /(release\s+version:\s+'#{release.version}',\s+crystax_version:\s+#{release.crystax_version},\s+sha256:\s+')(\h+)('.*)/
    s = File.read(path).sub(regexp, '\1' +  release.shasum + '\3')
    File.open(path, 'w') { |f| f.puts s }

    # we want archive modification time to be after formula file modification time
    # otherwise we'll be constantly rebuilding formulas for nothing
    FileUtils.touch archive
  end

  def copy_to_standalone_toolchain(_arch, _install_dir)
    warning "formula #{name} does not support copying to stanalone toolchain"
  end

  private

  def build_base_dir
    "#{Build::BASE_TARGET_DIR}/#{file_name}"
  end

  def build_log_file
    "#{build_base_dir}/build.log"
  end
end
