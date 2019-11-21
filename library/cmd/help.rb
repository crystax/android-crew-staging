require_relative '../exceptions.rb'
require_relative '../build.rb'
require_relative '../arch.rb'
require_relative '../platform.rb'
require_relative 'command.rb'


ENV_SYNTAX                       = 'env [options]'.freeze
LIST_SYNTAX                      = 'list [options] [name1 name2 ...]'.freeze
INFO_SYNTAX                      = 'info [options] name1 [name2 ...]'.freeze
INSTALL_SYNTAX                   = 'install [options] name[:version] ...'.freeze
SOURCE_SYNTAX                    = 'source [options] name[:version] ...'.freeze
BUILD_SYNTAX                     = 'build [options] name[:version] ...'.freeze
BUILD_CHECK_SYNTAX               = 'build-check [options] [name1 name2 ...]'.freeze
UPGRADE_SYNTAX                   = 'upgrade [options]'.freeze
CLEANUP_SYNTAX                   = 'cleanup [options]'.freeze
SHASUM_SYNTAX                    = 'shasum [options] [name1 name2 ...]'.freeze
MAKE_STANDALONE_TOOLCHAIN_SYNTAX = 'make-standalone-toolchain [options]'.freeze
MAKE_DEB_SYNTAX                  = 'make-deb [options] [name1 name2 ...]'.freeze
MAKE_POSIX_ENV_SYNTAX            = 'make-posix-env [options]'.freeze
TEST_SYNTAX                      = 'test [options] name[:version] ...'.freeze

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
  --help, -h      equivalent to crew help

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
  #{BUILD_CHECK_SYNTAX}
                  check if the specified formulas were build with outdated
                  or non-existing dependencies;
  remove-source name[:version] ...
                  remove source code for the specified formulas
  update          update crew repository information
  upgrade         install most recent versions
  #{CLEANUP_SYNTAX}
                  uninstall old versions and clean cache
  #{SHASUM_SYNTAX}
                  check or update SHA256 sums
  #{MAKE_STANDALONE_TOOLCHAIN_SYNTAX}
                  create a standalone toolchain package for Android
  #{MAKE_DEB_SYNTAX}
                  create a deb-format packages for a specified formulas;
                  formulas must be from a 'target' namespace
  #{MAKE_POSIX_ENV_SYNTAX}
                  create a tarball with a 'POSIX environment'a
  depends-on name
                  show packages that depend on the given package
  #{TEST_SYNTAX}
                  test the specified target formula(s)
EOS


NO_HELP = <<-EOS
There is no additional info for the command.
EOS

ENV_HELP = <<-EOS
#{ENV_SYNTAX}

The ENV command supports the following options:

  --download-base
                 output string used to build download URLs

  --base-dir     output path to crew's base directory

  --ndk-dir      output path to NDK directory

  --tools-dir    output path to crew's base directory

  --pkg-cache-dir
                 output path to the directory used as
                 a cache for crew packages

  --src-cache-dir
                 output path to the directory used as
                 a cache for sources for the crew packages

  --deb-cache-dir
                 output path to the directory used as
                 a cache for crew's packages in deb format

  --platform-name
                 output crew's platform

  --base-build-dir
                 output path to the base build directory

  --git-origin
                 output origin url

EOS

LIST_HELP = <<-EOS
#{LIST_SYNTAX}

The LIST command supports the following options:

  --packages     list only packages, t.i. formulas with
                 'target' namespace

  --tools        list only tools, t.i. formulas with
                 'host' namespace

  --no-title     do not output 'Tools:' and/or 'Packages'

  --names-only   output only formula names

\  --buildable-order
                 output formulas in buldable order, otherwise
                 formulas will be sorted by their names
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
                 found in the cache; this option can not be
                 specified with --ignore-cache

  --ignore-cache command will not look for the required package
                 in the cache; this option can not be specified
                 with --cache-only

  --force        install even if specified formula(s) installed

  --all-versions install all version of the specified formula(s)

  --with-dev-files
                 do not remove development files when installing
                 a package; makes sense only for utilities that
                 have a development files, ignored otherwise
EOS

SOURCE_HELP = <<-EOS
#{SOURCE_SYNTAX}

#{NAME_RULES}

The SOURCE command support the following options:

  --all-versions install source code for all version of the specified
                 formula(s)
  --force        if required source are already installed then remove them
                 and install afresh
  --ignore-cache do not check if reqired tarball was already downloaded
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

  --num-jobs=N   set number of jobs for a make command;
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
                 available ABIs are armeabi-v7a, armeabi-v7a-hard,
                 x86, mips, arm64-v8a, x86_64, mips64
                 by default the formula will be built for all ABIs
EOS

BUILD_CHECK_HELP = <<-EOS
#{BUILD_CHECK_SYNTAX}

If no formula name was specified then all formulas will be checked.
The BUILD-CHECK command support the following options:

  --show-bad-only
                 output information only for formulas that have
                 some issues

EOS

UPGRADE_HELP = <<-EOS
#{UPGRADE_SYNTAX}

The UPGRADE command support the following options:

  --no-check-shasum
                 do not check SHA256 sum of the packages before
                 installing them

  -n, --dry-run  don't actually upgrade anything, just print what
                 will be done

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

  --platforms=LIST
                 the list of platforms for which command will check or
                 update SHA256 sums of NDK's tools; platforms must be
                 separated with comma; available platforms are
                 darwin-x86_64; linux-x86_64, windows-x86_64, windows;
                 default value is #{Global::PLATFORM_NAME}

If no formula name was specified then all formulas will be handled.

If no option was specified then command will work as if '--check'
option was specified.
EOS


MAKE_STANDALONE_TOOLCHAIN_HELP = <<-EOS
#{MAKE_STANDALONE_TOOLCHAIN_SYNTAX}

Generate a customized Android toolchain installation that includes
a working sysroot. The result is something that can more easily be
used as a standalone cross-compiler, e.g. to run configure and
make scripts.

The MAKE-STANDALONE-TOOLCHAIN command supports the following options:

  --clean-install-dir
                 clean install directory before installing toolchain
                 files

  --install-dir=PATH
                 install files to PATH; if --clean-install-dir was not
                 specified then PATH must point to an empty or
                 non-existent directory; required
  --gcc-version=VER
                 specify GCC version; possible values are #{Toolchain::SUPPORTED_GCC.map(&:version).join(', ')};
                 default value is '#{Toolchain::DEFAULT_GCC.version}'

  --llvm-version=VER
                 specify LLVM version; possible values are #{Toolchain::SUPPORTED_LLVM.map(&:version).join(', ')};
                 default value is '#{Toolchain::DEFAULT_LLVM.version}'

  --stl=NAME     specify C++ STL; possible values are 'gnustl', 'libc++';
                 default value is 'gnustl'

  --arch=NAME    specify target architecture; possible values are
                 #{Arch::LIST.values.map(&:name).join(', ')}

  --platform=NAME
                 specify host system; possible value on darwin host is
                 darwin-x86_64, on linux host is linux-x86_64, on windows
                 64-bit host is windows-x86_64 or windows, on windows
                 32-bit host is windows

  --api-level=LEVEL
                 specify target Android API level; default value is #{Arch::MIN_32_API_LEVEL}
                 for 32-bit architectures and #{Arch::MIN_64_API_LEVEL} for 64-bit architectures

  --with-packages=LIST
                 specify names of the packages that should be copied
                 into toolchain installation tree; package names must
                 be separated by comma and can include required version
                 (i.e. boost:1.64.0); if version not specified then the
                 latest version will be used; only one version of the
                 given package can be installed
EOS


MAKE_DEB_HELP = <<-EOS
#{MAKE_DEB_SYNTAX}

The MAKE-DEB command generates deb-format packages for the specified
formulas. Formulas must be from the 'target' namespace. If no name was
specified then command will make debs for all target formulas.

A formula name can contain a desired version. If version is not
specified then command will use the latest version in a formula.

The command will use binary packages from the crew packages cache when
possible. Otherwise required packages will be downloaded from a
repository (but not installed).

The command supports the following options:

  --deb-repo-base=PATH
                  the path to a repository where the command will put
                  built deb packages; the command will create
                  subdirectories for each deb arch and put respective
                  packages there; default value is
                  #{Global::DEB_CACHE_DIR}

  --abis=LIST     list of abis for which deb packages should be
                  generated

  --all-versions  generate deb packages for all versions

  --no-clean      do not remove working directories; by default all
                  working directories will be removed after required
                  packages were created

  --no-check-shasum
                 do not check SHA256 sum of the packages before
                 using them
EOS


MAKE_POSIX_ENV_HELP = <<-EOS
#{MAKE_POSIX_ENV_SYNTAX}

The MAKE_POSIX_ENV creates direcory structure and fills it with the
required files and, optionally, packs the whole structure into tarball
that can be easily transferred to a target device using adb push
command.

The content of the directory structure is intended to emulate normal
POSIX environment on an Android device and contains all necessary binary
and configuration files.

The command supports the following options:

  --top-dir=PATH  top level directory where all the files will be copied

  --abi=ABI       the abi of the target device for which environment
                  will be created

  --no-tarball    do not pack resulting directory

  --no-check-shasum
                 do not check SHA256 sum of the packages before
                 using them

  --with-packages=LIST
                 specify names of the packages that should be added
                 to posix environment

  --minimize     strip all elf files before coping
EOS

TEST_HELP = <<-EOS
#{TEST_SYNTAX}

Name for the target formula can be just name or name and version, separated by colon: 'name:version'.

The TEST command supports the following options:

  --all-versions build all versions; by default, the command will build
                 only latest version

  --num-jobs=N   set number of jobs for a make command;
                 default value depends on the machine used;

  --abis=LIST    the list of ABIs for which to test formulas;
                 ABIs must be separated with comma;
                 available ABIs are armeabi-v7a, armeabi-v7a-hard,
                 x86, mips, arm64-v8a, x86_64, mips64
                 by default the formula will be tested for all ABIs

  --toolchains=LIST
                the list of toolchains to use to build tests;
                toolchains must be separated by comma;
                available toolchains are
                #{(Toolchain::SUPPORTED_GCC+Toolchain::SUPPORTED_LLVM).join(', ')}
                default value is '#{Toolchain::DEFAULT_GCC.version}'
EOS


CMD_HELP = {
  'version'                   => NO_HELP,
  'help'                      => NO_HELP,
  'env'                       => ENV_HELP,
  'list'                      => LIST_HELP,
  'info'                      => INFO_HELP,
  'install'                   => INSTALL_HELP,
  'remove'                    => NO_HELP,
  'source'                    => SOURCE_HELP,
  'build'                     => BUILD_HELP,
  'build-check'               => BUILD_CHECK_HELP,
  'remove-source'             => NO_HELP,
  'update'                    => NO_HELP,
  'upgrade'                   => UPGRADE_HELP,
  'cleanup'                   => CLEANUP_HELP,
  'shasum'                    => SHASUM_HELP,
  'make-standalone-toolchain' => MAKE_STANDALONE_TOOLCHAIN_HELP,
  'make-deb'                  => MAKE_DEB_HELP,
  'make-posix-env'            => MAKE_POSIX_ENV_HELP,
  'depends-on'                => NO_HELP,
  'test'                      => TEST_HELP
}


module Crew

  def self.help(args)
    Help.new(args).execute
  end

  class Help < Command

    def initialize(args)
      super args
    end

    def execute
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
end


  # todo: test types
  # --types=LIST   the list of test types that should be performed;
  #                types must be separated by comma;
  #                avaliable types are 'build', 'device' and 'own';
  #                by default command will execute all test types
  #                avaliable for a given formula

  # --cxx-runtimes=LIST
  #               the list of C++ runtimes to use when building tests
  #               written in C++ language; available values are
  #               'gnustl' and 'c++'; by default tests will be built
  #               with gnustl C++ runtime

  # --cxx-runtime-types=LIST
  #               the list of C++ runtime types separated by comma; available
  #               values are 'shared', 'static'; default value is 'shared'
