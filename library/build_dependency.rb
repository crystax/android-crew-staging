require 'digest'
require_relative 'tool.rb'
require_relative 'properties.rb'
require_relative 'platform.rb'
require_relative 'for_host_buildable.rb'


class BuildDependency < Tool

  INSTALL_DIR_NAME = 'build_dependencies'

  include Properties
  include ForHostBuildable

  def initialize(path)
    super path

    # mark installed releases
    releases.each { |r| r.update get_properties(release_directory(r)) }
  end

  def home_directory(platform_name)
    File.join(Global.shipyard_dir(platform_name), file_name)
  end

  def release_directory(release, platform_name = Global::PLATFORM_NAME)
    File.join(home_directory(platform_name), release.to_s)
  end

  def type
    :build_dependency
  end

  def build_dependencies
    dependencies
  end

  def install_archive(release, archive, platform_name = Global::PLATFORM_NAME, ndk_dir = Global::NDK_DIR)
    rel_dir = release_directory(release, platform_name)
    FileUtils.rm_rf rel_dir
    Utils.unpack archive, ndk_dir

    prop = get_properties(rel_dir)
    prop[:installed] = true
    prop[:installed_crystax_version] = release.crystax_version
    save_properties prop, rel_dir

    release.installed = release.crystax_version
  end
end
