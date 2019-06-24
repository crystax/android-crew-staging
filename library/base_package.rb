require_relative 'global.rb'
require_relative 'target_base.rb'


class BasePackage < TargetBase

  def properties_directory(release, _platform_name = nil)
    File.join(Global::SERVICE_DIR, file_name, release.version)
  end

  def source_installed?(release)
    true
  end

  def install_archive(release, archive, _platform_name = nil)
    remove_installed_files release

    puts "Unpacking archive into #{release_directory(release)}"
    Utils.unpack archive, Global::NDK_DIR

    prop_dir = properties_directory(release)
    prop = get_properties(prop_dir)
    prop[:installed] = true
    prop[:installed_crystax_version] = release.crystax_version
    save_properties prop, prop_dir

    release.installed = release.crystax_version
  end

  def uninstall(release)
    puts "removing #{name}:#{release.version}"

    remove_installed_files
    FileUtils.rm_f properties_directory(release)

    release.installed = false
  end

  def write_build_info(release, package_dir)
    prop_dir = File.join(package_dir, File.basename(Global::SERVICE_DIR), file_name, release.version)
    prop = { build_info: @host_build_info + @target_build_info }
    save_properties prop, prop_dir
  end
end
