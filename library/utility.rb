require 'digest'
require_relative 'tool.rb'
require_relative 'platform.rb'
require_relative 'build.rb'
require_relative 'build_options.rb'
require_relative 'for_host_buildable.rb'


class Utility < Tool

  INSTALL_DIR_NAME = 'crew'
  ACTIVE_FILE_NAME = 'active_version.txt'

  include ForHostBuildable

  def self.active_path(util_name, engine_dir = Global::ENGINE_DIR)
    File.join(engine_dir, util_name, ACTIVE_FILE_NAME)
  end

  def self.active_version(util_name, engine_dir = Global::ENGINE_DIR)
    file = Utility.active_path(util_name, engine_dir)
    File.exists?(file) ? File.read(file).split("\n")[0] : nil
  end

  def self.active_dir(util_name, engine_dir = Global::ENGINE_DIR)
    File.join(engine_dir, util_name, active_version(util_name, engine_dir), 'bin')
  end

  # For utilities a release considered as 'installed' only if it's version is equal
  # to the one saved in the 'active' file.
  #
  def initialize(path)
    super(path)

    # todo: handle platform dependant installations
    if not av = Utility.active_version(file_name)
      # todo: output warning
    else
      ver, cxver = Release.split_package_version(av)
      releases.each { |r| r.installed = cxver if r.version == ver }
    end
  end

  def home_directory(platform_name)
    File.join(Global.engine_dir(platform_name), file_name)
  end

  def release_directory(release, platform_name = Global::PLATFORM_NAME)
    File.join(home_directory(platform_name), release.to_s)
  end

  def active_version(engine_dir = Global::ENGINE_DIR)
    Utility.active_version file_name, engine_dir
  end

  def install_archive(release, archive, platform_name = Global::PLATFORM_NAME, ndk_dir = Global::NDK_DIR)
    rel_dir = release_directory(release, platform_name)
    FileUtils.rm_rf rel_dir
    # use system tar while updating bsdtar utility
    Utils.reset_tar_prog if name == 'bsdtar'
    Utils.unpack archive, ndk_dir
    write_active_file File.dirname(rel_dir), release
    Utils.reset_tar_prog if name == 'bsdtar'
    release.installed = release.crystax_version
  end

  private

  def write_active_file(home_dir, release)
    file = File.join(home_dir, ACTIVE_FILE_NAME)
    File.open(file, 'w') { |f| f.puts release.to_s }
  end
end
