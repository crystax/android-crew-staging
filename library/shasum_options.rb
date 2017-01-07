require_relative 'global.rb'
require_relative 'utils.rb'
require_relative 'build.rb'
require_relative 'command_options.rb'


class ShasumOptions

  extend CommandOptions

  def initialize(opts)
    @update = nil
    @all_versions = nil

    opts.each do |opt|
      case opt
      when /^--update=/
        u = opt.split('=')[1]
        raise "bad update value: #{u}; must be 'all' or 'last'" if u != 'all' and u != 'last'
        @update = true
        @all_versions = true
      else
        raise "unknow option: #{opt}"
      end
    end
  end

  def update?
    @update
  end

  def all_versions?
    @all_versions
  end
end
