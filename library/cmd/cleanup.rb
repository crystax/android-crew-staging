require 'fileutils'
require_relative '../exceptions.rb'
require_relative '../utils.rb'
require_relative '../release.rb'
require_relative '../formulary.rb'
require_relative 'command.rb'
require_relative 'cleanup/options.rb'

module Crew

  def self.cleanup(args)
    Cleanup.new(args).execute
  end

  class Cleanup < Command

    RemoveData = Struct.new(:archive, :reason)

    def initialize(args)
      super args, Options

      raise CommandRequresNoArguments if self.args.count > 0
    end

    def execute
      if options.clean_pkg_cache?
        clean_pkg_cache
      else
        puts "Sorry, other functionality not implemented yet"
      end

      # incache = []
      # Formulary.utilities.each { |formula| incache += remove_old_utilities(formula) }
      # Formulary.packages.each { |formula| incache += remove_old_libraries(formula) }

      # incache.each do |f|
      #   if options.dry_run?
      #     puts "would remove: #{f}"
      #   else
      #     puts "removing: #{f}"
      #     FileUtils.remove_file(f)
      #   end
      # end
    end

    private

    def clean_pkg_cache
      remove = []
      split_formulary = { host: formulary.tools, target: formulary.packages }
      [:host, :target].each do |ns|
        Dir["#{Global::PKG_CACHE_DIR}/#{Global::NS_DIR[ns]}/*"].each do |archive|
          filename, pkgver, _ = Utils.split_archive_path(archive)
          begin
            version, crystax_version = Utils.split_package_version(pkgver)
            required_release = Release.new(version, crystax_version)
            formula = split_formulary[ns].select { |f| f.file_name == filename }[0]
            raise FormulaUnavailableError.new(filename) unless formula
            found = formula.releases.select { |r| r.version == required_release.version and r.crystax_version == required_release.crystax_version }
            raise "#{formula.name} has no release #{required_release}" if found.empty?
          rescue Exception => e
            remove << RemoveData.new(archive, e.to_s)
          end
        end
      end

      remove.each do |data|
        if options.dry_run?
          puts "would remove: #{data.archive}; reason: #{data.reason}"
        else
          puts "removing: #{data.archive}; reason: #{data.reason}"
          FileUtils.rm_rf data.archive
        end
      end
    end

    def remove_old_utilities(formula)
      active_ver = formula.active_version
      home_dir = formula.home_directory(Global::PLATFORM_NAME)
      #
      Dir[File.join(home_dir, '*')].select { |d| File.directory?(d) and (File.basename(d) != active_ver) }.sort.each do |dir|
        if (options.dry_run?)
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

    def remove_old_libraries(formula)
      incache = []
      # releases are sorted from oldest to most recent order
      latest_rel = formula.releases.select { |r| r.installed? }.last
      if not latest_rel
        incache = Dir[File.join(Global::PKG_CACHE_DIR, "#{formula.name}-*.tar.xz")].sort
      else
        Dir[File.join(formula.home_directory, '*')].select { |d| File.basename(d) != latest_rel.version }.sort.each do |dir|
          if (options.dry_run?)
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
end
