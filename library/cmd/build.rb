require_relative '../exceptions.rb'
require_relative '../release.rb'
require_relative '../formulary.rb'
require_relative '../build_options.rb'


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
      raise "source code not installed for #{formula.name}:#{release}" if (formula.namespace == :target) and !formula.source_installed?(release)

      # todo: check that (build) dependencies installed for all required platforms
      deps = formula.dependencies + formula.build_dependencies
      absent = deps.select { |d| not formulary[d.fqn].installed? }
      raise "uninstalled dependencies: #{absent.map(&:fqn).join(',')}" unless absent.empty?

      host_deps, target_deps = deps.partition { |d| d.namespace == :host }

      host_dep_dirs = Hash.new { |h, k| h[k] = Hash.new }
      host_deps.each do |d|
        f = formulary[d.fqn]
        options.platforms.each do |platform|
          dep = { f.name => f.release_directory(f.highest_installed_release, platform) }
          host_dep_dirs[platform].update dep
        end
      end

      # really stupid hash behaviour: just Hash.new({}) does not work
      target_dep_dirs = {}
      target_deps.each do |d|
        f = formulary[d.fqn]
        target_dep_dirs[f.name] = f.release_directory(f.highest_installed_release)
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
