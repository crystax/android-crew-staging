require 'digest'

require_relative 'utils.rb'
require_relative 'tool.rb'
require_relative 'platform.rb'
require_relative 'build.rb'
require_relative 'build_options.rb'


class Utility < Tool

  ACTIVE_FILE_NAME = 'active_version.txt'

  def self.active_path(util_name, utilities_dir = Global::UTILITIES_DIR)
    File.join(utilities_dir, util_name, ACTIVE_FILE_NAME)
  end

  def self.active_version(util_name, utilities_dir = Global::UTILITIES_DIR)
    file = Utility.active_path(util_name, utilities_dir)
    File.exists?(file) ? File.read(file).split("\n")[0] : nil
  end

  def self.active_dir(util_name, utilities_dir = Global::UTILITIES_DIR)
    File.join(utilities_dir, util_name, active_version(util_name, utilities_dir), 'bin')
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
      ver, cxver = Utils.split_package_version(av)
      releases.each { |r| r.installed = cxver if r.version == ver }
    end
  end

  def home_directory(platform_name)
    File.join(Global.utilities_dir(platform_name), file_name)
  end

  def release_directory(release, platform_name = Global::PLATFORM_NAME)
    File.join(home_directory(platform_name), release.to_s)
  end

  def active_version(utilities_dir = Global::UTILITIES_DIR)
    Utility.active_version file_name, utilities_dir
  end

  def install_archive(release, archive, platform_name)
    rel_dir = release_directory(release, platform_name)
    FileUtils.rm_rf rel_dir

    # use system tar while updating bsdtar utility
    Utils.reset_tar_prog if name == 'bsdtar'
    Utils.unpack archive, Global::NDK_DIR
    write_active_file File.dirname(rel_dir), release
    Utils.reset_tar_prog if name == 'bsdtar'

    release.installed = release.crystax_version

    executables.each { |e| write_wrapper_script(e, platform_name) }
  end

  def executables
    self.class.executables
  end

  def self.executables(*args)
    if args.size == 0
      @executables ? @executables : []
    else
      @executables = args
    end
  end

  private

  def write_active_file(home_dir, release)
    file = File.join(home_dir, ACTIVE_FILE_NAME)
    File.open(file, 'w') { |f| f.puts release.to_s }
  end

  def wrapper_script_lines(_exe, _platform_name)
    []
  end

  def write_wrapper_script(exe, platform_name)
    wrapper = File.join(Global::NDK_DIR, 'prebuilt', platform_name, 'bin', exe)
    wrapper += '.cmd' if platform_name.start_with?('windows')
    FileUtils.mkdir_p File.dirname(wrapper)

    if not platform_name.start_with?('windows')
      sub_dir = "#{File.basename(Global::UTILITIES_DIR)}/#{file_name}"
      File.open(wrapper, 'w') do |f|
        f.puts '#!/bin/bash'
        f.puts
        wrapper_script_lines(exe, platform_name).each { |l| f.puts l }
        f.puts
        f.puts 'tools_dir=$(dirname $0)/..'
        f.puts "ver=`cat $tools_dir/#{sub_dir}/#{ACTIVE_FILE_NAME}`"
        f.puts "dir=\"$tools_dir/#{sub_dir}/$ver/bin\""
        f.puts
        f.puts "exec $dir/#{exe} \"$@\""
      end
      FileUtils.chmod "a+x", wrapper
    else
      sub_dir = "#{File.basename(Global::UTILITIES_DIR)}\\#{file_name}"
      exe += '.exe'
      File.open(wrapper, 'w') do |f|
        f.puts '@echo off'
        f.puts
        f.puts 'setlocal'
        f.puts
        wrapper_script_lines(exe, platform_name).each { |l| f.puts l }
        f.puts
        f.puts 'set FILEDIR=%~dp0'
        f.puts 'set TOOLSDIR=%FILEDIR%..'
        f.puts
        f.puts 'set VER='
        f.puts "pushd %TOOLSDIR%\\#{sub_dir}"
        f.puts "for /f \"delims=\" %%a in ('type #{ACTIVE_FILE_NAME}') do @set VER=%%a"
        f.puts 'popd'
        f.puts "set DIR=%TOOLSDIR%\\#{sub_dir}\\%VER%\\bin"
        f.puts
        f.puts "%DIR%\\#{exe} %*"
        f.puts
        f.puts 'endlocal'
        f.puts
        f.puts 'exit /b %errorlevel%'
      end
    end
  end
end
