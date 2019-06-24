require_relative '../../exceptions.rb'
require_relative '../command.rb'


module Crew

  class Info < Command

    class Options < Command::Options

      attr_reader :show_info, :build_info_platforms

      def initialize(opts)
        @show_info = :all
        @build_info_platforms = [Global::PLATFORM_NAME]

        opts.each do |opt|
          case opt
          when '--versions-only'
            @show_info = :versions
          when '--path-only'
            @show_info = :path
          when '--build-info-platforms'
            @build_info_platforms = opt.split('=')[1].split(',')
            check_platform_names *@build_info_platforms
          else
            raise UnknownOption, opt
          end
        end
      end
    end
  end
end
