require_relative '../../global.rb'
require_relative '../../utils.rb'
require_relative '../../build.rb'
require_relative '../../platform.rb'
require_relative '../command.rb'


module Crew

  class Shasum < Command

    class Options < Command::Options

      attr_accessor :platforms

      def initialize(opts)
        @update = false
        @platforms = [Global::PLATFORM_NAME]

        opts.each do |opt|
          case opt
          when /^--update$/
            @update = true
          when /^--check$/
            @update = false
          when /^--platforms=/
            @platforms = opt.split('=')[1].split(',')
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
  end
end
