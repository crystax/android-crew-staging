require_relative '../formulary.rb'


module Crew

  class Command

    # class Options

    #   def parse_args(args)
    #     [[], args]
    #   end
    # end

    attr_reader :formulary, :options
    attr_accessor :args

    def initialize(args, options)
      @formulary = Formulary.new
      @options, @args = options.parse_args(args)
    end
  end
end
