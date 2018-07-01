require 'fileutils'
require_relative '../formulary.rb'
require_relative 'make_posix_env_options.rb'


ETC_ENVIRONMENT_FILE_STR = %q(# The most important environment variables

# This file MUST be sourced before starting to use Crystax POSIX environment
top_dir=$(dirname $(dirname ${BASH_SOURCE[0]}))
#echo "top_dir=$top_dir"

PATH=$top_dir/bin:$top_dir/usr/bin:$top_dir/sbin:$PATH
export PATH

LD_LIBRARY_PATH=$top_dir/lib:$top_dir/usr/lib
export LD_LIBRARY_PATH

CRYSTAX_POSIX_BASE=$top_dir
export CRYSTAX_POSIX_BASE

DPKG_ADMINDIR=$top_dir/var/lib/dpkg
export DPKG_ADMINDIR

TERMINFO=$top_dir/usr/share/terminfo
export TERMINFO

unset top_dir
)

ETC_BASH_PROFILE_STR = %q(# Common bash_profile

test -n "$BASH" && export SHELL=$BASH

etcdir34b728476740cc8e8=$(dirname ${BASH_SOURCE[0]})
test -e $etcdir34b728476740cc8e8/environment && source $etcdir34b728476740cc8e8/environment

shopt -s checkwinsize
shopt -s cmdhist
shopt -s cdspell
shopt -s progcomp
shopt -s histappend

export HISTCONTROL=ignoreboth:erasedups

BLACK='\[\033[01;30m\]'
GREEN='\[\033[01;32m\]'
RED='\[\033[01;31m\]'
YELLOW='\[\033[01;33m\]'
BLUE='\[\033[01;34m\]'
BOLD='\[\033[01;39m\]'
CYAN='\[\033[01;36m\]'
MAGENTA='\[\033[01;35m\]'
DARKMAGENTA='\[\033[00;35m\]'
NORM='\[\033[00m\]'

SHELLNAME=$(basename $SHELL)
OS=$(uname -o | tr '[a-z]' '[A-Z]')

PS1="${YELLOW}${SHELLNAME}${NORM} [${GREEN}\u@\h ${DARKMAGENTA}${OS} ${CYAN}\t ${BLUE}\w${NORM}]$ "
export PS1

unset SHELLNAME
unset OS

unset BLACK
unset GREEN
unset RED
unset YELLOW
unset BLUE
unset BOLD
unset CYAN
unset MAGENTA
unset DARKMAGENTA
unset NORM

test -e $etcdir34b728476740cc8e8/bashrc && source $etcdir34b728476740cc8e8/bashrc

unset etcdir34b728476740cc8e8
)

ETC_BASHRC_STR = %q(# Common bashrc
umask 002

alias mv='mv -i'
alias cp='cp -i'
alias ll='ls --color=auto -FAl'
alias tf='tail -F'
alias pg='ps auxw | grep -v grep | grep'
)

ROOT_BASH_PROFILE_STR = %q(source $(dirname ${BASH_SOURCE[0]})/etc/bash_profile)


module Crew

  DEF_PACKAGES = %w[
    libcrystax bash coreutils gnu-grep gnu-sed gnu-which gnu-tar gzip findutils less xz
  ]

  ENVIRONMENT_FILE = 'environment'

  def self.make_posix_env(args)
    options, args = MakePosixEnvOptions.parse_args(args)

    formulary = Formulary.new
    package_names = DEF_PACKAGES + options.with_packages
    packages, dependencies = packages_formulas(formulary, package_names)

    puts "create POSIX environment in: #{options.top_dir}"
    puts "for ABI:                     #{options.abi}"
    puts "packages:                    #{packages.map(&:name).join(',')}"
    puts "dependencies:                #{dependencies.map(&:name).join(',')}"

    top_dir = options.top_dir
    FileUtils.rm_rf top_dir
    FileUtils.mkdir_p top_dir

    puts "copying formulas:"
    (packages + dependencies).each do |formula|
      release = formula.releases.last
      puts "  #{formula.name}:#{release}"
      deb_file = formula.deb_cache_file(release, options.abi)
      if not File.exist?(deb_file)
        shasum = options.check_shasum? ? formula.read_shasum(release) : nil
        formula.download_archive(release, nil, shasum, false)
        make_deb_archive formula.name, release.version, options
      end
      Deb.install_deb_archive formula, top_dir, deb_file, options.abi
    end

    FileUtils.mkdir_p "#{top_dir}/etc"
    File.open("#{top_dir}/etc/#{ENVIRONMENT_FILE}", 'w') { |f| f.puts ETC_ENVIRONMENT_FILE_STR }
    File.open("#{top_dir}/etc/bash_profile", 'w') { |f| f.puts ETC_BASH_PROFILE_STR }
    File.open("#{top_dir}/etc/bashrc", 'w') { |f| f.puts ETC_BASHRC_STR }
    File.open("#{top_dir}/.bash_profile", 'w') { |f| f.puts ROOT_BASH_PROFILE_STR }

    Dir.chdir(File.join(top_dir, 'bin')) do
      system('bash coreutils-create-symlinks.sh')
      FileUtils.rm 'coreutils-create-symlinks.sh'

      FileUtils.ln_s 'bash', 'sh' unless File.exists?('sh')
    end

    Dir.chdir(top_dir) do
      FileUtils.chmod_R 'u+w', top_dir

      toolchain = Build::DEFAULT_TOOLCHAIN
      arch = Build.abis_to_arch_list([options.abi]).first
      readelf = toolchain.tool(arch, 'readelf')
      strip   = toolchain.tool(arch, 'strip')

      files = Dir.glob(File.join(top_dir, '**', '*')).select { |e| File.file?(e) && !File.symlink?(e) }

      files.sort.each do |e|
        _, status = Process.wait2 Kernel.spawn(readelf, '-h', e, out: '/dev/null', err: '/dev/null')
        next unless status.success?

        puts "  strip: #{e}"
        _, status = Process.wait2 Kernel.spawn(strip, e)
        fail unless status.success?
      end

    end if options.minimize?

    if options.make_tarball?
      archive = "#{top_dir}.tar.bz2"
      puts "creating tarball: #{archive}"
      Utils.run_command Utils.tar_prog, '--format', 'ustar', '-C', File.dirname(top_dir), '-jcf', archive, File.basename(top_dir)
    end
  end

  def self.packages_formulas(formulary, package_names)
    packages = package_names.map { |n| "target/#{n}" }.map { |n| formulary[n] }
    deps = packages.reduce([]) { |acc, f| acc + formulary.dependencies(f) }.uniq(&:name).sort { |f1, f2| f1.name <=> f2.name }
    [packages, deps - packages]
  end

  def self.make_deb_archive(name, version, options)
    cmd_with_args = ["#{Global::BASE_DIR}/crew", 'make-deb', "--abis=#{options.abi}"]
    cmd_with_args << '--no-check-shasum' unless options.check_shasum?
    cmd_with_args << "#{name}:#{version}"
    system *cmd_with_args
  end
end
