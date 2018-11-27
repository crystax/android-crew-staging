require_relative '../../exceptions.rb'
require_relative '../../arch.rb'
require_relative '../../utils.rb'
require_relative '../command.rb'


module Crew

  class Test < Command

    class Options < Command::Options

      TOOLCHAIN_NAMES = (Toolchain::SUPPORTED_GCC + Toolchain::SUPPORTED_LLVM).map(&:to_s)
      TYPE_LIST       = %w[build run]

      attr_accessor :abis, :num_jobs, :types, :toolchains

      def initialize(opts)
        @num_jobs = Utils.processor_count * 2
        @abis = Arch::ABI_LIST.dup
        @types = ['build']
        @toolchains = TOOLCHAIN_NAMES.dup
        @all_versions = false

        opts.each do |opt|
          case opt
          when '--all-versions'
            @all_versions = true
          when /^--num-jobs=/
            @num_jobs = opt.split('=')[1].to_i
          when /^--abis=/
            @abis = opt.split('=')[1].split(',')
            check_abis *@abis
          when /^--types=/
            @types = opt.split('=')[1].split(',')
            @types.each { |type| raise "unknown test type '#{type}'" unless TYPE_LIST.include? type }
          when /^--toolchains=/
            @toolchains = opt.split('=')[1].split(',')
            @toolchains.each { |toolchain| raise "unknown toolchain '#{toolchain}'" unless TOOLCHAIN_NAMES.include? toolchain }
          else
            raise UnknownOption, opt
          end
        end

      end

      def all_versions?
        @all_versions
      end
    end
  end
end
