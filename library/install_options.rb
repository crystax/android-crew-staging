require_relative 'global.rb'
require_relative 'utils.rb'
require_relative 'build.rb'
require_relative 'command_options.rb'


class InstallOptions

  extend CommandOptions

  attr_accessor :platform
  attr_writer :check_shasum

  def initialize(opts)
    @platform = Global::PLATFORM_NAME
    @check_shasum = true

    opts.each do |opt|
      case opt
      when '--no-check-shasum'
        @check_shasum = false
      when /^--platform=/
        @platform = opt.split('=')[1]
      else
        raise "unknow option: #{opt}"
      end
    end
  end

  def check_shasum?
    @update_shasum
  end
end
