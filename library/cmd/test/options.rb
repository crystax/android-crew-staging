require_relative '../../arch.rb'
require_relative '../../utils.rb'
require_relative '../../command_options.rb'


module Crew

  class Test

    class Options

      extend CommandOptions

      TOOLCHAIN_NAMES       = (Toolchain::SUPPORTED_GCC + Toolchain::SUPPORTED_LLVM).map(&:to_s)
      TYPE_LIST             = %w[build run]

      attr_accessor :abis, :num_jobs, :types, :toolchains

      def initialize(opts)
        @all_versions = false
        @num_jobs = Utils.processor_count * 2
        @abis = Arch::ABI_LIST.dup
        @types = ['build']
        @toolchains = TOOLCHAIN_NAMES.dup

        opts.each do |opt|
          case opt
          when '--all-versions'
            @all_versions = true
          when /^--num-jobs=/
            @num_jobs = opt.split('=')[1].to_i
          when /^--abis=/
            @abis = opt.split('=')[1].split(',')
          when /^--types=/
            @types = opt.split('=')[1].split(',')
          when /^--toolchains=/
            @toolchains = opt.split('=')[1].split(',')
          else
            raise "unknow option: #{opt}"
          end
        end

        @abis.each              { |abi|       raise "unknown abi '#{abi}'"              unless Arch::ABI_LIST.include?        abi       }
        @types.each             { |type|      raise "unknown test type '#{type}'"       unless TYPE_LIST.include?             type      }
        @toolchains.each        { |toolchain| raise "unknown toolchain '#{toolchain}'"  unless TOOLCHAIN_NAMES.include?       toolchain }
      end

      def all_versions?
        @all_versions
      end
    end
  end
end
