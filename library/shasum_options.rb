require_relative 'global.rb'
require_relative 'utils.rb'
require_relative 'build.rb'
require_relative 'command_options.rb'


class ShasumOptions

  extend CommandOptions

  def initialize(opts)
    @update = false

    opts.each do |opt|
      case opt
      when /^--update$/
        @update = true
      when /^--check$/
        @update = false
      else
        raise "unknow option: #{opt}"
      end
    end
  end

  def update?
    @update == true
  end

  def check?
    @update == false
  end
end
