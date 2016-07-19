require_relative '../exceptions.rb'
require_relative '../release.rb'
require_relative '../formulary.rb'
require_relative '../build_options.rb'


module Crew

  def self.build(args)
    raise NoBuildOnWindows if Global::OS == 'windows'

    options, args = parse_args(args)
    raise FormulaUnspecifiedError if args.count < 1

    formulary = Formulary.all_formulas

    args.each do |n|
      item, ver = n.split(':')

      type, formula = find_formula_and_type(item, formulary)

      release = formula.find_release(Release.new(ver))
      raise "source code not installed for #{formula.name}:#{release}" if (type == :package) and !(release.source_installed?)

      # todo: check that dependencies installed for all required platforms
      check_dependencies formula.build_dependencies, formulary[type]
      dep_dirs = make_dep_dirs(formula, type, formulary[type], options.platforms)

      formula.build_package release, options, dep_dirs

      puts "" unless n == args.last
    end
  end

  def self.find_formula_and_type(item, formulary)
    type, name = Formula.type_name(item)
    if type
      [type, formulary[type][name]]
    else
      r = []
      Formula::TYPES.each do |t|
        fs = formulary[t]
        r << [t, fs[item]] if fs.member? item
      end
      raise "formula with name #{item} not found" if r.size == 0
      raise "#{item} has more than one type: #{r}; please, specify required formula type" if r.size > 1
      r[0]
    end
  end

  def self.make_dep_dirs(formula, type, formulary, platforms)
    if type == :package
      dependencies_dirs formulary, formulary
    else
      dependencies_dirs_with_platforms(formula, formulary, platforms)
    end
  end

  def self.dependencies_dirs(formula, formulary)
    dep_dirs = {}
    Formula.full_dependencies(formulary, formula.dependencies).each do |f|
      dep_dirs[f.name] = f.release_directory(f.highest_installed_release)
    end

    dep_dirs
  end

  def self.dependencies_dirs_with_platforms(formula, formulary, platforms)
    # really stupid hash behaviour: just Hash.new({}) does not work
    dep_dirs = Hash.new { |h, k| h[k] = Hash.new }
    Formula.full_dependencies(formulary, formula.build_dependencies).each do |f|
      platforms.each do |platform|
        dep = { f.name => f.release_directory(f.highest_installed_release, platform) }
        dep_dirs[platform].update dep
      end
    end

    dep_dirs
  end

  def self.check_dependencies(dependencies, formulary)
    absent = dependencies.select { |d| not formulary[d.name].installed? }
    raise "uninstalled build dependencies: #{absent.map{|d| d.name}.join(',')}" unless absent.empty?
  end

  def self.parse_args(args)
    opts = args.take_while { |a| a.start_with? '--' }
    args = args.drop_while { |a| a.start_with? '--' }

    [Build_options.new(opts), args]
  end
end
