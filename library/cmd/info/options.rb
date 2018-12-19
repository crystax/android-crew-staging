require_relative '../../exceptions.rb'
require_relative '../command.rb'


module Crew

  class Info < Command

    class Options < Command::Options

      attr_reader :show_info

      def initialize(opts)
        @show_info = :all

        opts.each do |opt|
          case opt
          when '--versions-only'
            @show_info = :versions
          when '--path-only'
            @show_info = :path
          else
            raise UnknownOption, opt
          end
        end
      end
    end
  end
end
