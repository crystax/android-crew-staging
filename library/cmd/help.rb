require_relative '../exceptions.rb'
require_relative '../build.rb'


CREW_HELP = <<-EOS
Usage: crew [OPTIONS] COMMAND [parameters]

where

OPTIONS are:
  --backtrace, -b output backtrace with exception message;
                  debug option

COMMAND is one of the following:
  version         output version information
  help [command]...
                  if no command specified show this help message;
                  otherwise show addition info for the specified commands
  env             show crew's command working environment
  list [libs|utils]
                  list all available formulas for libraries or utilities;
                  whithout an argument list all formulas
  info name ...   show information about the specified formula(s)
  install name[:version] ...
                  install the specified formula(s)
  remove name[:version] ...
                  uninstall the specified formulas
  source name[:version] ...
                  install source code for the specified formula(s)
  build [build_options] name[:version] ...
                  build the specified formula(s) from the source code
  remove-source name[:version] ...
                  remove source code for the specified formulas
  update          update crew repository information
  upgrade         install most recent versions
  cleanup [-n]    uninstall old versions and clean cache
EOS


NO_HELP = <<-EOS
There is no additional info the command.
EOS

BUILD_HELP = <<-EOS
The command support the following options:

--abis=LIST      the list of ABIs, for which to build formula;
                 ABIs must be separted with comma;
                 available ABIs are armeabi, armeabi-v7a, armeabi-v7a-hard,
                 x86, mips, arm64-v8a, x86_64, mips64
                 by default the formula will be built for all ABIs

--build-only     do not create package in the cache dir and do not install
                 formula

--no-clean       do not remove build artifacts

--update-shasum  calculate SHA256 sum of the package and update formula

--num-jobs=N     set number of jobs for a make commad;
                 default value depends on the machine used

EOS

CMD_HELP = {
  'version'       => NO_HELP,
  'help'          => NO_HELP,
  'env'           => NO_HELP,
  'list'          => NO_HELP,
  'info'          => NO_HELP,
  'install'       => NO_HELP,
  'remove'        => NO_HELP,
  'source'        => NO_HELP,
  'build'         => BUILD_HELP,
  'remove-source' => NO_HELP,
  'update'        => NO_HELP,
  'upgrade'       => NO_HELP,
  'cleanup'       => NO_HELP
}

module Crew
  def self.help(args)
    case args.size
    when 0
      puts CREW_HELP
    else
      args.each do |cmd|
        raise "unknown command '#{cmd}'" unless CMD_HELP.keys.include? cmd
        puts "'#{cmd.upcase}'"
        puts ''
        puts CMD_HELP[cmd]
      end
    end
  end
end
