module TestBasePackageMethods

  def home_directory
    File.join(Global::HOLD_DIR, file_name)
  end

  def release_directory(release, _platform_name = nil)
    File.join(home_directory, release.version)
  end

  def properties_directory(release)
    release_directory release
  end

  def install_archive(release, archive, _platform_name = nil)
    prop_dir = properties_directory(release)
    FileUtils.mkdir_p prop_dir unless Dir.exists? prop_dir
    prop = get_properties(prop_dir)

    FileUtils.rm_rf "#{Global::NDK_DIR}/#{archive_sub_dir(release)}"
    Utils.unpack archive, Global::NDK_DIR

    prop[:installed] = true
    prop[:installed_crystax_version] = release.crystax_version
    save_properties prop, prop_dir

    release.installed = release.crystax_version
  end

    def uninstall(release)
    puts "removing #{name}:#{release.version}"

    FileUtils.rm_rf "#{Global::NDK_DIR}/#{archive_sub_dir(release)}"

    prop_dir = properties_directory(release)
    prop = get_properties(prop_dir)
    prop[:installed] = false
    prop.delete :installed_crystax_version
    save_properties prop, prop_dir

    release.installed = false
  end

  def archive_sub_dir(release)
    "packages/#{release.version}"
  end
end
