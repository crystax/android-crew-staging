require_relative '../exceptions.rb'
require_relative '../build.rb'


ENV_SYNTAX           = 'env [options]'.freeze
LIST_SYNTAX          = 'list [options] [name1 name2 ...]'.freeze
INFO_SYNTAX          = 'info [options] name1 [name2 ...]'.freeze
INSTALL_SYNTAX       = 'install [options] name[:version] ...'.freeze
SOURCE_SYNTAX        = 'source [options] name[:version] ...'.freeze
BUILD_SYNTAX         = 'build [options] name[:version] ...'.freeze
CLEANUP_SYNTAX       = 'cleanup [options]'.freeze
SHASUM_SYNTAX        = 'shasum [options] [name1 name2 ...]'.freeze

NAME_RULES = <<-EOS
Name for a formula can specified in two ways. First, it can be specified
with formula type, like this:

  target/openssl

or

  host/openssl

Second, it can be specified without any type prefix, like this:

  libjpeg

If type is not specified, then command will find out formula's type
automatically. Specifing formula type is required only if formula with
the same name exists for more than one type.
EOS

CREW_HELP = <<-EOS
Usage: crew [OPTIONS] COMMAND [parameters]

where

OPTIONS are:
  --backtrace, -b output backtrace with exception message;
                  debug option

  --no-warnings, -W
                  do not output warnings

COMMAND is one of the following:
  version         output version information
  help [command]...
                  if no command specified show this help message;
                  otherwise show addition info for the specified commands
  #{ENV_SYNTAX}   show crew's command working environment
  #{LIST_SYNTAX}
                  list the specified formulas;
                  whithout any options and arguments list all formulas
  #{INFO_SYNTAX}
                  show information about the specified formula(s)
  #{INSTALL_SYNTAX}
                  install the specified formula(s)
  remove name[:version] ...
                  uninstall the specified formulas
  #{SOURCE_SYNTAX}
                  install source code for the specified formula(s)
  #{BUILD_SYNTAX}
                  build the specified formula(s) from the source code
  remove-source name[:version] ...
                  remove source code for the specified formulas
  update          update crew repository information
  upgrade         install most recent versions
  #{CLEANUP_SYNTAX}
                  uninstall old versions and clean cache
  #{SHASUM_SYNTAX}
                  check or update SHA256 sums
EOS


NO_HELP = <<-EOS
There is no additional info for the command.
EOS

ENV_HELP = <<-EOS
#{ENV_SYNTAX}

The ENV command supports the following options:

  --pkg-cache-dir
                 output path to the directory used as
                 a cache for crew packages

  --src-cache-dir
                 output path to the directory used as
                 a cache for sources for the crew packages

EOS

LIST_HELP = <<-EOS
#{LIST_SYNTAX}

The LIST command supports the following options:

Filters:

  --packages     list only packages, t.i. formulas with
                 'target' namespace

  --tools        list only tools, t.i. formulas with
                 'host' namespace
EOS

INFO_HELP = <<-EOS
#{INFO_SYNTAX}

The INFO command supports the following options:

  --versions-only
                 for every specified name list only avaliable
                 versions
  --path-only    for every specified name list only formula
                 path

Options --versions-only and --filename-only are mutually exclusive.
EOS

INSTALL_HELP = <<-EOS
#{INSTALL_SYNTAX}

#{NAME_RULES}

The INSTALL command support the following options:

  --platform=PLATFORM
                 One of the supported platforms: darwin-x86_64;
                 linux-x86_64, windows-x86_64, windows;
                 by default the platforms on which the command
                 is run will be used

  --no-check-shasum
                 do not check SHA256 sum of the packages before
                 installing them

  --cache-only   command will fail if required package was not
                 found in the cache

  --force        install even if specified formula(s) installed

  --all-versions install all version of the specified formula(s)
EOS

SOURCE_HELP = <<-EOS
#{SOURCE_SYNTAX}

#{NAME_RULES}

The SOURCE command support the following options:

  --all-versions install source code for all version of the specified
                 formula(s)
EOS

BUILD_HELP = <<-EOS
#{BUILD_SYNTAX}

#{NAME_RULES}

The BUILD command supports the following options:

Common options:

  --build-only   do not create package in the cache dir and do not install
                 formula; implies --no-clean

  --no-install   do not install built package

  --no-clean     do not remove build artifacts

  --update-shasum
                 calculate SHA256 sum of the package and update formula

  --num-jobs=N   set number of jobs for a make commad;
                 default value depends on the machine used

  --all-versions build all versions; by default, the command will build
                 only latest version

Options for building utilities:

  --source-only  just prepare sources for building and do nothing else;
                 implies --no-clean

  --platforms=LIST
                 the list of platforms for which to build formulas;
                 platforms must be separated with comma;
                 available platforms on darwin hosts are darwin-x86_64;
                 available platforms on linux hosts are linux-x86_64,
                 windows-x86_64, windows;
                 by default all platforms available on the given host
                 will be built

  --check        run tests if host OS and platform OS are the same;
                 by default tests will not be run

Options for building target packages:

  --abis=LIST    the list of ABIs for which to build formulas;
                 ABIs must be separated with comma;
                 available ABIs are armeabi, armeabi-v7a, armeabi-v7a-hard,
                 x86, mips, arm64-v8a, x86_64, mips64
                 by default the formula will be built for all ABIs
EOS

CLEANUP_HELP = <<-EOS
#{CLEANUP_SYNTAX}

The CLEANUP command supports the following options:

  -n, --dry-run  don't actually remove files, just print them

  --pkg-cache    cleanup package cache; the command will remove from
                 package cache all archives that are not described in
                 any formula
EOS

SHASUM_HELP = <<-EOS
#{SHASUM_SYNTAX}

The SHASUM command supports the following options:

  --update       for every specified formula check SHA256 sum and if
                 check fails then calculate sum and save it to the
                 formula file

  --check        check SHA256 sum for every release of every specified
                 formula

If no formula name was specified then all formulas will be handled.

If no option was specified then command will work as if '--check'
option was specified.
EOS

CMD_HELP = {
  'version'       => NO_HELP,
  'help'          => NO_HELP,
  'env'           => ENV_HELP,
  'list'          => LIST_HELP,
  'info'          => INFO_HELP,
  'install'       => INSTALL_HELP,
  'remove'        => NO_HELP,
  'source'        => SOURCE_HELP,
  'build'         => BUILD_HELP,
  'remove-source' => NO_HELP,
  'update'        => NO_HELP,
  'upgrade'       => NO_HELP,
  'cleanup'       => CLEANUP_HELP,
  'shasum'        => SHASUM_HELP
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
