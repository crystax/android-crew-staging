require 'rugged'
require_relative '../exceptions.rb'
require_relative '../build.rb'
require_relative 'command.rb'

module Crew

  def self.env(args)
    Env.new(args).execute
  end

  class Env < Command

    def initialize(args)
      super args
    end

    def execute
      origin = Rugged::Repository.new(Global::BASE_DIR).remotes['origin'].url

      if args.length == 0
        puts "DOWNLOAD_BASE:  #{Global::DOWNLOAD_BASE}"
        puts "PKG_CACHE_DIR:  #{Global::PKG_CACHE_DIR}"
        puts "SRC_CACHE_DIR:  #{Global::SRC_CACHE_DIR}"
        puts "DEB_CACHE_DIR:  #{Global::DEB_CACHE_DIR}"
        puts "BASE_DIR:       #{Global::BASE_DIR}"
        puts "NDK_DIR:        #{Global::NDK_DIR}"
        puts "TOOLS_DIR:      #{Global::TOOLS_DIR}"
        puts "PLATFORM_NAME:  #{Global::PLATFORM_NAME}"
        puts "BASE_BUILD_DIR: #{Build::BASE_BUILD_DIR}"
        puts "GIT origin:     #{origin}"
      else
        args.each do |arg|
          case arg
          when '--download-base'  then puts Global::DOWNLOAD_BASE
          when '--base-dir'       then puts Global::BASE_DIR
          when '--ndk-dir'        then puts Global::NDK_DIR
          when '--tools-dir'      then puts Global::TOOLS_DIR
          when '--pkg-cache-dir'  then puts Global::PKG_CACHE_DIR
          when '--src-cache-dir'  then puts Global::SRC_CACHE_DIR
          when '--deb-cache-dir'  then puts Global::DEB_CACHE_DIR
          when '--platform-name'  then puts Global::PLATFORM_NAME
          when '--base-build-dir' then puts Build::BASE_BUILD_DIR
          when '--git-origin'     then puts origin
          else
            raise "bad option: #{arg}"
          end
        end
      end
    end
  end
end
