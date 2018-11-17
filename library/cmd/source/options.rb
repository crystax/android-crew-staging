require_relative '../../global.rb'
require_relative '../../utils.rb'
require_relative '../../build.rb'
require_relative '../command.rb'
require_relative '../../command_options.rb'


module Crew

  class Source < Command

    class Options

      extend CommandOptions

      attr_accessor :platform

      def initialize(opts)
        @all_versions = false

        opts.each do |opt|
          case opt
          when '--all-versions'
            @all_versions = true
          else
            raise "unknow option: #{opt}"
          end
        end
      end

      def all_versions?
        @all_versions
      end
    end
  end
end
