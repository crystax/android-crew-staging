require 'digest'
require_relative 'utils.rb'
require_relative 'tool.rb'
require_relative 'properties.rb'
require_relative 'platform.rb'


class BuildDependency < Tool

  # tool trait
  INSTALL_DIR_NAME = File.basename(Global::SHIPYARD_DIR)  #'build_dependencies'

  include Properties

  def initialize(path)
    super path

    # mark installed releases
    Platform::NAMES.each do |platform|
      Dir["#{home_directory(platform)}/*"].each do |file|
        if not File.directory? file
          # todo: out warning
        else
          ver, cxver = Utils.split_package_version(File.basename(file))
          # todo: output warning if there is no release for the ver
          releases.each { |r| r.installed = cxver if r.version == ver }
        end
      end
    end
  end

  def home_directory(platform_name)
    File.join(Global.shipyard_dir(platform_name), file_name)
  end

  def release_directory(release, platform_name = Global::PLATFORM_NAME)
    File.join(home_directory(platform_name), release.to_s)
  end

  def install_archive(release, archive, platform_name)
    rel_dir = release_directory(release, platform_name)
    FileUtils.rm_rf rel_dir
    Utils.unpack archive, Global::NDK_DIR

    release.installed = release.crystax_version
  end
end
