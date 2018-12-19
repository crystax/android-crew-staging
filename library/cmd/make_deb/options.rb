require_relative '../../exceptions.rb'
require_relative '../../arch.rb'
require_relative '../command.rb'


module Crew

  class MakeDeb < Command

    class Options < Command::Options

      attr_accessor :deb_repo_base, :abis

      def initialize(opts)
        @deb_repo_base = Global::DEB_CACHE_DIR
        @abis = Arch::ABI_LIST
        @all_versions = false
        @clean = true
        @check_shasum = true

        opts.each do |opt|
          case opt
          when /^--deb-repo-base=/
            @deb_repo_base = opt.split('=')[1]
          when '--all-versions'
            @all_versions = true
          when /^--abis=/
            @abis = opt.split('=')[1].split(',')
            check_abis *@abis
          when '--no-clean'
            @clean = false
          when '--no-check-shasum'
            @check_shasum = false
          else
            raise UnknownOption, opt
          end
        end
      end

      def all_versions?
        @all_versions
      end

      def clean?
        @clean
      end

      def check_shasum?
        @check_shasum
      end
    end
  end
end
