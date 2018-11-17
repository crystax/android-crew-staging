require_relative '../command.rb'
require_relative '../../command_options.rb'

module Crew

  class DependsOn < Command

    class Options

      extend CommandOptions

      def initialize(_args)
      end
    end
  end
end
