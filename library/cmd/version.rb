require_relative '../exceptions.rb'
require_relative '../global.rb'
require_relative 'command.rb'

module Crew

  def self.version(args)
    Version.new(args).execute
  end

  class Version < Command

    def initialize(args)
      super args
      raise CommandRequresNoArguments if args.length > 0
    end

    def execute
      puts Global::VERSION
    end
  end
end
