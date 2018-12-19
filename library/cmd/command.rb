require_relative '../exceptions.rb'
require_relative '../arch.rb'
require_relative '../platform.rb'
require_relative '../formulary.rb'


module Crew

  class Command

    class Options

      def self.parse_args(args)
        # todo: use more sophisticated conditions to select options?
        opts, args = args.partition { |a| a.start_with? '-' }
        [self.new(opts), args]
      end

      def check_abis(*abis)
        if abis.empty?
          raise "no abi was specified"
        else
          bad_abis = abis - Arch::ABI_LIST
          raise UnknownAbi.new(*bad_abis) unless bad_abis.empty?
        end
      end

      def check_platform_names(*names)
        if names.empty?
          raise "no platform names was specified"
        else
          bad_names = names - Platform::NAMES
          raise UnknownPlatform.new(*bad_names) unless bad_names.empty?
        end
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
