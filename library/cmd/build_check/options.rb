require_relative '../../exceptions.rb'
require_relative '../command.rb'


module Crew

  class BuildCheck < Command

    class Options < Command::Options

      def initialize(opts)
        @show_bad_only = false

        opts.each do |opt|
          case opt
          when '--show-bad-only'
            @show_bad_only = true
          else
            raise UnknownOption, opt
          end
        end
      end

      def show_bad_only?
        @show_bad_only
      end
    end
  end
end
