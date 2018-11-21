require_relative '../command.rb'


module Crew

  class Cleanup < Command

    class Options < Command::Options

      def initialize(opts)
        @dry_run = false
        @clean_pkg_cache = false
        @clean_src_cache = false

        if opts.empty? || (opts.size == 1 && (opts[0] == '-n' || opts[0] == '--dry-run'))
          @clean_pkg_cache = true
          @clean_src_cache = true
        end

        opts.each do |opt|
          case opt
          when '-n', '--dry-run'
            @dry_run = true
          when '--pkg-cache'
            @clean_pkg_cache = true
          when '--src-cache'
            @clean_src_cache = true
          else
            raise "unknow option: #{opt}"
          end
        end
      end

      def dry_run?
        @dry_run
      end

      def clean_pkg_cache?
        @clean_pkg_cache
      end

      def clean_src_cache?
        @clean_src_cache
      end
    end
  end
end
