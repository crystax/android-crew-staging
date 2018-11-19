require_relative '../formulary.rb'


module Crew

  class Command

    class Options

      def self.parse_args(args)
        # todo: use more sophisticated conditions to select options?
        opts, args = args.partition { |a| a.start_with? '-' }
        [self.new(opts), args]
      end
    end

    attr_reader :formulary, :options
    attr_accessor :args

    def initialize(args, options = nil)
      @formulary = Formulary.new
      if options
        @options, @args = options.parse_args(args)
      else
        @options = nil
        @args = args
      end
    end
  end
end
