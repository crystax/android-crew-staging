require_relative '../exceptions.rb'
require_relative '../build.rb'


BUILD_SYNTAX = 'build [build_options] name[:version] ...'.freeze

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
  list [--packages|--tools]
                  list all available formulas for packages or tools;
                  whithout an argument list all formulas
  info name ...   show information about the specified formula(s)
  install name[:version] ...
                  install the specified formula(s)
  remove name[:version] ...
                  uninstall the specified formulas
  source name[:version] ...
                  install source code for the specified formula(s)
  #{BUILD_SYNTAX}
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
#{BUILD_SYNTAX}

Name for a formula to build can specified in two ways. First, it can be
specified with formula type, like this:

  package/openssl

or

  utility/openssl

Second, it can be specified without any type prefix, like this:

  libjpeg

If type is not specified, then BUILD command will find out formula's type
automatically. Specifing formula type is required only if formula with
the same name exists for more than one type.

The BUILD command support the following options:

Common options:

--source-only    just prepare sources for building and do nothing else;
                 implies --no-clean

--build-only     do not create package in the cache dir and do not install
                 formula; implies --no-clean

--no-install     do not install built package

--no-clean       do not remove build artifacts

--update-shasum  calculate SHA256 sum of the package and update formula

--num-jobs=N     set number of jobs for a make commad;
                 default value depends on the machine used

Options for building utilities:

--platforms=LIST the list of platforms for which to build formulas;
                 platforms must be separated with comma;
                 available platforms on darwin hosts are darwin-x86_64;
                 available platforms on linux hosts are linux-x86_64,
                 windows-x86_64, windows;
                 by default all platforms available on the given host
                 will be built

--check          run tests if host OS and platform OS are the same;
                 by default tests will not be run

Options for building libraries:

--abis=LIST      the list of ABIs for which to build formulas;
                 ABIs must be separated with comma;
                 available ABIs are armeabi, armeabi-v7a, armeabi-v7a-hard,
                 x86, mips, arm64-v8a, x86_64, mips64
                 by default the formula will be built for all ABIs
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
        puts CMD_HELP[cmd]
      end
    end
  end
end
