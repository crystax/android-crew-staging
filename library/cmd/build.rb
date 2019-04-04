require_relative '../exceptions.rb'
require_relative '../release.rb'
require_relative 'command.rb'
require_relative 'build/options.rb'
require_relative 'source.rb'


module Crew

  def self.build(args)
    Build.new(args).execute
  end

  TargetDepInfo = Struct.new(:release, :release_directory)

  class Build < Command

    def initialize(args)
      super args, Options

      raise NoBuildOnWindows        if Global::OS == 'windows'
      raise FormulaUnspecifiedError if self.args.count < 1
    end

    def execute
      options.parse_packages_options args, formulary

      add_all_versions if options.all_versions?

      args.each do |n|
        item, ver = n.split(':')
        formula = formulary[item]
        release = formula.find_release(Release.new(ver))

        # automatically install sources if not yet installed
        Crew.source ["#{formula.name}:#{release.version}"] if (formula.namespace == :target && !formula.source_installed?(release))

        # todo: check that (build) dependencies installed for all required platforms
        deps = formulary.dependencies(formula, with_build_deps: true)
        absent = deps.select { |d| not d.formula.installed?(d.version) }
        unless absent.empty?
          uds = absent.map do |d|
            unless d.version
              d.fqn
            else
              rs = d.formula.find_matched_releases(d.version)
              d.fqn + ':' + rs.join('|')
            end
          end
          raise "uninstalled dependencies: #{uds.join(',')}"
        end

        # check that dependencies installed with dev files
        no_dev_files = deps.select do |d|
          unless d.formula.has_dev_files?
            false
          else
            rs = d.formula.find_matched_releases(d.version)
            rs.any? { |r| r.installed? && !d.formula.dev_files_installed?(r) }
          end
        end
        raise "dependencies with uninstalled dev files: #{no_dev_files.map(&:fqn).join(',')}" unless no_dev_files.empty?

        host_deps, target_deps = deps.partition { |d| d.namespace == :host }

        # really stupid hash behaviour: just Hash.new({}) does not work
        host_dep_dirs = Hash.new { |h, k| h[k] = Hash.new }
        host_deps.each do |d|
          f = formulary[d.fqn]
          options.platforms.each do |platform|
            rel = d.version ? f.find_release(d.version) : f.highest_installed_release
            dep = { f.name => f.code_directory(rel, platform) }
            host_dep_dirs[platform].update dep
          end
        end

        target_dep_info = {}
        target_deps.each do |d|
          f = formulary[d.fqn]
          rel = d.version ? f.find_release(d.version) : f.highest_installed_release
          target_dep_info[f.fqn] = TargetDepInfo.new(rel, f.release_directory(rel))
        end

        formula.build release, options, host_dep_dirs, target_dep_info

        puts "" unless n == args.last
      end
    end

    def add_all_versions
      a = []
      args.each do |n|
        item, _ = n.split(':')
        formulary[item].releases.each { |r| a << "#{item}:#{r.version}" }
      end
      self.args = a
    end
  end
end
