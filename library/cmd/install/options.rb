require_relative '../../exceptions.rb'
require_relative '../../global.rb'
require_relative '../command.rb'


module Crew

  class Install < Command

    class Options < Command::Options

      attr_accessor :platform

      def self.default_as_hash
        Options.new([]).as_hash
      end

      def initialize(opts)
        @platform = Global::PLATFORM_NAME
        @check_shasum = true
        @cache_only = false
        @ignore_cache = false
        @force = false
        @all_versions = false
        @with_dev_files = false

        opts.each do |opt|
          case opt
          when '--no-check-shasum'
            @check_shasum = false
          when /^--platform=/
            @platform = opt.split('=')[1]
            check_platform_names @platform
          when '--cache-only'
            raise IncompatibleOptions.new('--cache-only', '--ignore-cache') if @ignore_cache
            @cache_only = true
          when '--ignore-cache'
            raise IncompatibleOptions.new('--ignore-cache', '--cache-only') if @cache_only
            @ignore_cache = true
          when '--force'
            @force = true
          when '--all-versions'
            @all_versions = true
          when '--with-dev-files'
            @with_dev_files = true
          else
            raise UnknownOption, opt
          end
        end
      end

      def check_shasum?
        @check_shasum
      end

      def cache_only?
        @cache_only
      end

      def ignore_cache?
        @ignore_cache
      end

      def force?
        @force
      end

      def all_versions?
        @all_versions
      end

      def with_dev_files?
        @with_dev_files
      end

      def as_hash
        { platform:       self.platform,
          check_shasum:   self.check_shasum?,
          cache_only:     self.cache_only?,
          ignore_cache:   self.ignore_cache?,
          force:          self.force?,
          all_versions:   self.all_versions?,
          with_dev_files: self.with_dev_files?
        }
      end
    end
  end
end
