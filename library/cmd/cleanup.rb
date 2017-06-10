require 'fileutils'
require_relative '../exceptions.rb'
require_relative '../utils.rb'
require_relative '../release.rb'
require_relative '../formulary.rb'
require_relative 'cleanup_options.rb'

module Crew

  RemoveData = Struct.new(:archive, :reason)

  def self.cleanup(args)
    options, args = CleanupOptions.parse_args(args)
    raise CommandRequresNoArguments if args.count > 0

    formulary = Formulary.new

    if options.clean_pkg_cache?
      clean_pkg_cache formulary, options.dry_run?
    else
      puts "Sorry, other functionality not implemented yet"
    end

    # incache = []
    # Formulary.utilities.each { |formula| incache += remove_old_utilities(formula, dryrun) }
    # Formulary.packages.each { |formula| incache += remove_old_libraries(formula, dryrun) }

    # incache.each do |f|
    #   if (dryrun)
    #     puts "would remove: #{f}"
    #   else
    #     puts "removing: #{f}"
    #     FileUtils.remove_file(f)
    #   end
    # end
  end

  # private

  def self.clean_pkg_cache(formulary, dry_run)
    remove = []
    split_formulary = { host: formulary.tools, target: formulary.packages }
    [:host, :target].each do |ns|
      Dir["#{Global::PKG_CACHE_DIR}/#{Global::NS_DIR[ns]}/*"].each do |archive|
        filename, pkgver = File.basename(archive).split('-')
        begin
          version, crystax_version = Utils.split_package_version(pkgver)
          formulas = split_formulary[ns].select { |f| f.file_name == filename }
          raise FormulaUnavailableError.new(name) if formulas.empty?
          formulas[0].find_release(Release.new(version, crystax_version))
        #rescue FormulaUnavailableError, ReleaseNotFound, Exception => e
        rescue Exception => e
          remove << RemoveData.new(archive, e.to_s)
        end
      end
    end

    remove.each do |data|
      if dry_run
        puts "would remove: #{data.archive}; reason: #{data.reason}"
      else
        puts "removing: #{data.archive}; reason: #{data.reason}"
        FileUtils.rm_rf data.archive
      end
    end
  end

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
    Dir[File.join(Global::PKG_CACHE_DIR, mask)].select { |f| File.basename(f) != active }
  end

  def self.remove_old_libraries(formula, dryrun)
    incache = []
    # releases are sorted from oldest to most recent order
    latest_rel = formula.releases.select { |r| r.installed? }.last
    if not latest_rel
      incache = Dir[File.join(Global::PKG_CACHE_DIR, "#{formula.name}-*.tar.xz")].sort
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
      incache = Dir[File.join(Global::PKG_CACHE_DIR, "#{formula.name}-*.tar.xz")].select { |f| File.basename(f) != latest }.sort
    end

    incache
  end
end
