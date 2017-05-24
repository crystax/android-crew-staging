require 'digest'
require_relative 'utils.rb'
require_relative 'tool.rb'
require_relative 'properties.rb'
require_relative 'platform.rb'


class BuildDependency < Tool

  # tool trait
  INSTALL_DIR_NAME =

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
    File.join(Global.build_dependencies_dir(platform_name), file_name)
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


  def install_dir_for_platform(platform_name, release)
    File.join package_dir_for_platform(platform_name), 'prebuilt', platform_name, Global::BUILD_DEPENDENCIES_BASE_DIR, file_name, release.to_s
  end
end
