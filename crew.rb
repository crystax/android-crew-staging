require 'fileutils'
require_relative 'library/extend/module.rb'
require_relative 'library/extend/dir.rb'
require_relative 'library/extend/io.rb'
require_relative 'library/exceptions.rb'
require_relative 'library/global.rb'
require_relative 'library/utils.rb'

def split_arguments(arguments)
  goptions = []
  cmd = 'help'
  args = []
  # get global options
  arguments.each.with_index do |arg, index|
    if arg =~ /^-.*/
      goptions << arg
      break if arg == '--help' or arg == '-h'
    else
      cmd = arg.to_s.gsub('-', '_').downcase
      args = arguments.slice(index + 1, arguments.length)
      break
    end
  end
  [goptions, cmd, args]
end

def require_command(cmd)
  path = File.join("library", "cmd", cmd + '.rb')
  require_relative path
rescue LoadError => e
  raise UnknownCommand, cmd, e.backtrace
end


if __FILE__ == $0
  begin
    goptions, cmd, args = split_arguments(ARGV)
    Global.set_options(goptions)

    FileUtils.cd(Global::BASE_DIR) do
      require_command(cmd)
      Crew.send(cmd, args)
    end
  rescue Exception => e
    exception(e)
    exit 1
  else
    exit 0
  end
end
