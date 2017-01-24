require_relative 'global.rb'
require_relative 'utils.rb'
require_relative 'build.rb'
require_relative 'command_options.rb'


class ShasumOptions

  extend CommandOptions

  attr_reader :platforms

  def initialize(opts)
    @update = nil
    @check = nil
    @all_versions = nil
    @platforms = [ Global::PLATFORM_NAME ]

    opts.each do |opt|
      case opt
      when /^--update=/
        u = opt.split('=')[1]
        raise "bad update value: #{u}; must be 'all' or 'last'" if u != 'all' and u != 'last'
        @update = true
        @check = false
        @all_versions = (u == 'all')
      when /^--platforms=/
        @platforms = opt.split('=')[1].split(',')
        @platforms.each { |p| raise "unsupported platform #{p}" unless Platform::NAMES.include? p }
      when /^--check$/
        @check = true
        @update = false
        @all_versions = true
        @platforms = Platform::NAMES
      else
        raise "unknow option: #{opt}"
      end
    end
  end

  def update?
    @update
  end

  def check?
    @check
  end

  def all_versions?
    @all_versions
  end
end
