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

  def copy_to_standalone_toolchain(_release, _arch, _target_include_dir, _target_lib_dir)
    warning "formula #{name} does not support copying to stanalone toolchain"
  end

  def make_target_lib_dirs(arch, target_dir)
    dirs = case arch.name
           when 'arm'
             ["lib/armv7-a", "lib/armv7-a/thumb", "lib/armv7-a/hard", "lib/armv7-a/thumb/hard"]
           when 'mips'
             ["lib", "libr2", "libr6"]
           when 'mips64'
             ["lib", "libr2", "libr6", "lib64", "lib64r2"]
           when 'x86_64'
             ["lib", "lib64", "libx32"]
           else
             ["lib"]
           end

    FileUtils.cd(target_dir) { FileUtils.mkdir_p dirs }
  end

  private

  def build_base_dir
    "#{Build::BASE_TARGET_DIR}/#{file_name}"
  end

  def build_log_file
    "#{build_base_dir}/build.log"
  end
end
