require 'fileutils'
require_relative 'utility.rb'

class Library < Utility

  def has_dev_files?
    true
  end

  def dev_files_installed?(release, platform_name = Global::PLATFORM_NAME)
    File.exist? File.join(release_directory(release, platform_name), HostBase::DEV_LIST_FILE)
  end
end
