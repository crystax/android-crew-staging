module TestToolMethods

  def install_archive(release, archive, platform_name)
    rel_dir = release_directory(release, platform_name)
    FileUtils.mkdir_p rel_dir unless Dir.exists? rel_dir
    prop = get_properties(rel_dir)

    prop[:installed] = true
    prop[:installed_crystax_version] = release.crystax_version
    save_properties prop, rel_dir

    release.installed = release.crystax_version
  end

  def uninstall(release, platform_name = Global::PLATFORM_NAME)
    puts "removing #{name}:#{release.version} #{platform_name}"
    rel_dir = release_directory(release, platform_name)
    prop = get_properties(rel_dir)

    prop[:installed] = false
    prop.delete :installed_crystax_version
    save_properties prop, rel_dir

    release.installed = false
  end
end
