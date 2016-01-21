require_relative 'formula.rb'


class Utility < Formula

  # For utilities a release considered as 'installed' only if it's version is equal
  # to the one saved in the 'active' file.
  #
  # Utility ctor called with :no_active_file from the NDK's build scripts
  # in the case we should just mark all releases as 'uninstalled'
  def initialize(path, *options)
    super(path)

    if not options.include? :no_active_file
      ver, cxver = Formula.split_package_version(Global::active_util_version(name))
      releases.each { |r| r.installed = cxver if r.version == ver }
    end
  end

  def programs
    self.class.programs
  end

  def home_directory
    File.join(Global::ENGINE_DIR, name)
  end

  def release_directory(release)
    File.join(home_directory, release.to_s)
  end

  def download_base
    "#{Global::DOWNLOAD_BASE}/utilities"
  end

  def type
    :utility
  end

  private

  def archive_filename(release)
    "#{name}-#{Formula.package_version(release)}-#{Global::PLATFORM}.tar.xz"
  end

  def sha256_sum(release)
    release.shasum(Global::PLATFORM.gsub(/-/, '_').to_sym)
  end

  def install_archive(release, archive)
    rel_dir = release_directory(release)
    FileUtils.rm_rf rel_dir
    FileUtils.mkdir_p rel_dir
    Utils.unpack archive, Global::NDK_DIR
    write_active_file File.basename(rel_dir)
  end

  def write_active_file(version)
    File.open(Global.active_file_path(name), 'w') { |f| f.puts version }
  end
end
