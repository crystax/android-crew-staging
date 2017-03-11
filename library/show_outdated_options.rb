require_relative 'command_options.rb'


class ShowOutdatedOptions

  extend CommandOptions

  attr_reader :platforms

  def initialize(opts)
    @all_versions = false

    opts.each do |opt|
      case opt
      when /^--version=/
        u = opt.split('=')[1]
        case u
        when 'all'
          @all_versions = true
        when 'last'
          @all_versions = false
        else
          raise "bad version value: #{u}; must be 'all' or 'last'"
        end
      else
        raise "unknow option: #{opt}"
      end
    end
  end

  def all_versions?
    @all_versions
  end
end
