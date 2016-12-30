require_relative 'global.rb'
require_relative 'utils.rb'
require_relative 'build.rb'
require_relative 'command_options.rb'


class InstallOptions

  extend CommandOptions

  attr_accessor :platform

  def initialize(opts)
    @platform = Global::PLATFORM_NAME
    @check_shasum = true
    @cache_only = false
    @force = false
    @all_versions = false

    opts.each do |opt|
      case opt
      when '--no-check-shasum'
        @check_shasum = false
      when /^--platform=/
        @platform = opt.split('=')[1]
      when '--cache-only'
        @cache_only = true
      when '--force'
        @force = true
      when '--all-versions'
        @all_versions = true
      else
        raise "unknow option: #{opt}"
      end
    end
  end

  def check_shasum?
    @check_shasum
  end

  def cache_only?
    @cache_only
  end

  def force?
    @force
  end

  def all_versions?
    @all_versions
  end

  def as_hash
    { platform: self.platform, check_shasum: self.check_shasum?, cache_only: self.cache_only?, force: self.force?, all_versions: self.all_versions? }
  end
end
