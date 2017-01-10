require_relative 'global.rb'
require_relative 'target_base.rb'


class BasePackage < TargetBase

  def properties_directory(release)
    File.join(Global::SERVICE_DIR, file_name, release.version)
  end

  def source_installed?(release)
    true
  end
end
