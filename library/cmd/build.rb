require_relative '../exceptions.rb'
require_relative '../release.rb'
require_relative '../formulary.rb'
require_relative 'build_options.rb'
require_relative 'source.rb'


module Crew

  def self.build(args)
    raise NoBuildOnWindows if Global::OS == 'windows'

    options, args = BuildOptions.parse_args(args)
    raise FormulaUnspecifiedError if args.count < 1

    formulary = Formulary.new

    args = add_all_versions(args, formulary) if options.all_versions?

    args.each do |n|
      item, ver = n.split(':')
      formula = formulary[item]
      release = formula.find_release(Release.new(ver))

      # automatically install sources if not yet installed
      self.source ["#{formula.name}:#{release.version}"] if (formula.namespace == :target && !formula.source_installed?(release))

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

      target_dep_dirs = {}
      target_deps.each do |d|
        f = formulary[d.fqn]
        rel = d.version ? f.find_release(d.version) : f.highest_installed_release
        target_dep_dirs[f.name] = f.release_directory(rel)
      end

      formula.build release, options, host_dep_dirs, target_dep_dirs

      puts "" unless n == args.last
    end
  end

  def self.add_all_versions(args, formulary)
    a = []
    args.each do |n|
      item, _ = n.split(':')
      formulary[item].releases.each { |r| a << "#{item}:#{r.version}" }
    end
    a
  end
end
