require 'fileutils'
require_relative '../release.rb'
require_relative '../formulary.rb'
require_relative '../package.rb'
require_relative '../utility.rb'

module Crew

  def self.cleanup(args)
    case args.length
    when 0
      dryrun = false
    when 1
      if args[0] == '-n'
        dryrun = true
      else
        raise "this command accepts only one optional argument: -n"
      end
    else
      raise "this command accepts only one optional argument: -n"
    end

    incache = []
    Formulary.utilities.each { |formula| incache += remove_old_utilities(formula, dryrun) }
    Formulary.packages.each { |formula| incache += remove_old_libraries(formula, dryrun) }

    incache.each do |f|
      if (dryrun)
        puts "would remove: #{f}"
      else
        puts "removing: #{f}"
        FileUtils.remove_file(f)
      end
    end
  end

  # private

  def self.remove_old_utilities(formula, dryrun)
    active_ver = formula.active_version
    home_dir = formula.home_directory(Global::PLATFORM_NAME)
    #
    Dir[File.join(home_dir, '*')].select { |d| File.directory?(d) and (File.basename(d) != active_ver) }.sort.each do |dir|
      if (dryrun)
        puts "would remove: #{dir}"
      else
        puts "removing: #{dir}"
        FileUtils.rm_rf dir
      end
    end
    #
    mask = "#{formula.name}-*-#{Global::PLATFORM_NAME}.tar.xz"
    active = "#{formula.name}-#{active_ver}-#{Global::PLATFORM_NAME}.tar.xz"
    Dir[File.join(Global::CACHE_DIR, mask)].select { |f| File.basename(f) != active }
  end

  def self.remove_old_libraries(formula, dryrun)
    incache = []
    # releases are sorted from oldest to most recent order
    latest_rel = formula.releases.select { |r| r.installed? }.last
    if not latest_rel
      incache = Dir[File.join(Global::CACHE_DIR, "#{formula.name}-*.tar.xz")].sort
    else
      Dir[File.join(formula.home_directory, '*')].select { |d| File.basename(d) != latest_rel.version }.sort.each do |dir|
        if (dryrun)
          puts "would remove: #{dir}"
        else
          puts "removing: #{dir}"
          FileUtils.rm_rf dir
        end
      end
      latest = "#{formula.name}-#{latest_rel.version}_#{latest_rel.installed_crystax_version}.tar.xz"
      #puts "latest: #{latest}"
      #puts "file: " + Dir[File.join(Global::CACHE_DIR, "#{formula.name}-*.tar.xz")].to_s
      incache = Dir[File.join(Global::CACHE_DIR, "#{formula.name}-*.tar.xz")].select { |f| File.basename(f) != latest }.sort
    end

    incache
  end
end
