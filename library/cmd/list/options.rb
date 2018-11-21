require_relative '../../exceptions.rb'
require_relative '../../global.rb'
require_relative '../command.rb'


module Crew

  class List < Command

    class Options < Command::Options

      def initialize(opts)
        @list_tools = nil
        @list_packages = nil
        @no_title = false
        @names_only = false
        @buildable_order = false

        opts.each do |opt|
          case opt
          when '--tools'
            @list_tools = true
          when '--packages'
            @list_packages = true
          when '--no-title'
            @no_title = true
          when '--names-only'
            @names_only = true
          when '--buildable-order'
            @buildable_order = true
          else
            raise UnknownOption, opt
          end
        end

        if (@list_tools == nil) && (@list_packages == nil)
          @list_tools = true
          @list_packages = true
        end
      end

      def list_tools?
        @list_tools
      end

      def list_packages?
        @list_packages
      end

      def no_title?
        @no_title
      end

      def names_only?
        @names_only
      end

      def buildable_order?
        @buildable_order
      end
    end
  end
end
