require_relative '../../exceptions.rb'
require_relative '../../global.rb'
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
            check_platform_names *@platforms
          else
            raise UnknownOption, opt
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
