require_relative '../../exceptions.rb'
require_relative '../../global.rb'
require_relative '../../utils.rb'
require_relative '../../build.rb'
require_relative '../command.rb'


module Crew

  class Source < Command

    class Options < Command::Options

      attr_accessor :platform

      def initialize(opts)
        @all_versions = false
        @force = false

        opts.each do |opt|
          case opt
          when '--all-versions'
            @all_versions = true
          when '--force'
            @force = true
          else
            raise UnknownOption, opt
          end
        end
      end

      def all_versions?
        @all_versions
      end

      def force?
        @force
      end
    end
  end
end
