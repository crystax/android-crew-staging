require 'pathname'
require 'rugged'
require_relative 'exceptions.rb'
require_relative 'github.rb'

module Global

  # private

  def self.check_program(prog)
    raise "#{prog} is not executable" unless prog.exist? and prog.executable?
  end

  def self.operating_system
    h = RUBY_PLATFORM.split('-')
    case h[1]
    when /linux/
      'linux'
    when /darwin/
      'darwin'
    when /mingw/
      'windows'
    else
      raise "unsupported host OS: #{h[1]}"
    end
  end

  def self.def_tools_dir(ndkdir, os)
    case os
    when 'darwin', 'linux'
      "#{ndkdir}/prebuilt/#{os}-x86_64"
    else
      dir64 = "#{ndkdir}/prebuilt/windows-x86_64"
      dir32 = "#{ndkdir}/prebuilt/windows"
      Dir.exists?(dir64) ? dir64 : dir32
    end
  end

  def self.default_download_base(base_dir)
    # todo: when master will be available select it for master builds
    #       right now use staging download for all cases
    GitHub::STAGING_DOWNLOAD_BASE

    # origin = Rugged::Repository.new(base_dir).remotes['origin']

    # if origin and origin.url =~ /^(git@github.com:)|(https:\/\/).*android-crew-staging.git$/
    #   url = GitHub::STAGING_DOWNLOAD_BASE
    # else
    #   url = 'https://crew.crystax.net:9876'
    # end

    # url
  end

  # public

  BUILD_DEPENDENCIES_BASE_DIR = 'build_dependencies'

  def self.tools_dir(platform_name)
    File.join(NDK_DIR, 'prebuilt', platform_name)
  end

  def self.build_dependencies_dir(platform_name)
    File.join(tools_dir(platform_name), 'build_dependencies')
  end

  def self.raise_env_var_not_set(var)
    raise "#{var} environment varible is not set"
  end

  def self.set_options(opts)
    opts.each do |o|
      case o
      when '--backtrace', '-b'
        @options[:backtrace] = true
      when '--no-warnings', '-W'
        @options[:no_warnings] = true
      when '--help', '-h'
        # do nothing here
      else
        raise "unknown global option: #{o}"
      end
    end
  end

  def self.backtrace?
    @options[:backtrace]
  end

  def self.no_warnings?
    @options[:no_warnings]
  end

  def self.create_required_dir(*args)
    dir = Pathname.new(File.join(*args))
    FileUtils.mkdir_p dir unless dir.directory?
    dir
  end

  def self.default_src_cache_dir(os)
    case os
    when 'darwin'
      "#{ENV['HOME']}/Library/Caches/Crew/sources"
    when 'linux'
      "#{ENV['HOME']}/.caches/crew/sources"
    when 'windows'
      "#{BASE_DIR}/cache/sources"
    else
      raise UnsupportedOS.new(OS)
    end
  end

  def self.default_pkg_cache_dir(os)
    case os
    when 'darwin'
      "#{ENV['HOME']}/Library/Caches/crew"
    when 'linux'
      "#{ENV['HOME']}/.caches/crew"
    when 'windows'
      "#{BASE_DIR}/cache"
    else
      raise UnsupportedOS.new(OS)
    end
  end

  def self.pkg_cache_dir(formula)
    File.join(PKG_CACHE_DIR, NS_DIR[formula.namespace])
  end

  VERSION = "0.3.0"
  OS = operating_system

  BASE_DIR      = [nil, ''].include?(ENV['CREW_BASE_DIR'])      ? Pathname.new(__FILE__).realpath.dirname.dirname.to_s : Pathname.new(ENV['CREW_BASE_DIR']).realpath.to_s
  NDK_DIR       = [nil, ''].include?(ENV['CREW_NDK_DIR'])       ? Pathname.new(BASE_DIR).realpath.dirname.to_s         : Pathname.new(ENV['CREW_NDK_DIR']).realpath.to_s
  DOWNLOAD_BASE = [nil, ''].include?(ENV['CREW_DOWNLOAD_BASE']) ? default_download_base(BASE_DIR)                      : ENV['CREW_DOWNLOAD_BASE']
  SRC_CACHE_DIR = [nil, ''].include?(ENV['CREW_SRC_CACHE_DIR']) ? default_src_cache_dir(OS)                            : ENV['CREW_SRC_CACHE_DIR']
  PKG_CACHE_DIR = [nil, ''].include?(ENV['CREW_PKG_CACHE_DIR']) ? default_pkg_cache_dir(OS)                            : ENV['CREW_PKG_CACHE_DIR']
  TOOLS_DIR     = def_tools_dir(NDK_DIR, OS)

  PLATFORM_NAME = File.basename(TOOLS_DIR)

  NS_DIR = { host: 'tools', target: 'packages' }

  HOLD_DIR               = create_required_dir(NDK_DIR, 'packages').realpath
  SERVICE_DIR            = create_required_dir(NDK_DIR, '.crew').realpath
  PATCHES_DIR            = Pathname.new(File.join(BASE_DIR, 'patches')).realpath
  FORMULA_DIR            = Pathname.new(File.join(BASE_DIR, 'formula')).realpath

  _ = create_required_dir(SRC_CACHE_DIR)
  _ = create_required_dir(File.join(PKG_CACHE_DIR, NS_DIR[:host]))
  _ = create_required_dir(File.join(PKG_CACHE_DIR, NS_DIR[:target]))


  EXE_EXT  = RbConfig::CONFIG['EXEEXT']
  ARCH_EXT = 'tar.xz'

  # private

  @options = { backtrace: false, no_warnings: false }
end


def warning(msg)
  STDERR.puts "warning: #{msg}" unless Global.no_warnings?
end


def error(msg)
  STDERR.puts "error: #{msg}"
end


def exception(exc)
  error(exc)
  STDERR.puts exc.backtrace if Global.backtrace?
end
