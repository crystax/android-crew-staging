require_relative '../exceptions.rb'

module Crew

  def self.env(args)
    case args.length
    when 0
      puts "DOWNLOAD_BASE:  #{Global::DOWNLOAD_BASE}"
      puts "PKG_CACHE_BASE: #{Global::PKG_CACHE_BASE}"
      puts "SRC_CACHE_BASE: #{Global::SRC_CACHE_BASE}"
      puts "BASE_DIR:       #{Global::BASE_DIR}"
      puts "NDK_DIR:        #{Global::NDK_DIR}"
      puts "TOOLS_DIR:      #{Global::TOOLS_DIR}"
    when 1
      case args[0]
      when '--base-dir'
        puts Global::BASE_DIR
      when '--tools-dir'
        puts Global::TOOLS_DIR
      when '--pkg-cache-dir'
        puts Global::PKG_CACHE_DIR
      when '--src-cache-dir'
        puts Global::SRC_CACHE_DIR
      else
        raise "bad argument: #{args[0]}"
      end
    else
      raise CommandRequresOneOrNoArguments
    end
  end
end
