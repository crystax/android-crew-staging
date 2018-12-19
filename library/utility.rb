require 'digest'

require_relative 'utils.rb'
require_relative 'tool.rb'
require_relative 'platform.rb'
require_relative 'build.rb'


class Utility < Tool

  build_filelist true

  def code_directory(_release, platform_name)
    Global.tools_dir(platform_name)
  end

  private

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
