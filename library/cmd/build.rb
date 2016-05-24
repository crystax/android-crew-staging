require_relative '../exceptions.rb'
require_relative '../release.rb'
require_relative '../formulary.rb'
require_relative '../build_options.rb'


module Crew

  def self.build(args)
    raise NoBuildOnWindows if Global::OS == 'windows'

    options, args = parse_args(args)
    raise FormulaUnspecifiedError if args.count < 1

    packages = Formulary.packages
    utilities = Formulary.utilities

    args.each do |n|
      name, ver = n.split(':')

      if packages.member? name
        build_package packages[name], ver, packages, options
      elsif utilities.member? name
        build_utility utilities[name], ver, utilities, options
      else
        raise "#{name} not found amongst packages nor utilities"
      end

      puts "" unless n == args.last
    end
  end

  def self.build_package(formula, ver, formulary, options)
    release = formula.find_release(Release.new(ver))
    raise "source code not installed for #{name}:#{release}" unless release.source_installed?
    check_dependencies formula.dependencies, formulary

    dep_dirs = {}
    Formula.full_dependencies(formulary, formula.dependencies).each do |f|
      dep_dirs[f.name] = f.release_directory(f.highest_installed_release)
    end

    formula.build_package release, options, dep_dirs
  end

  def self.build_utility(formula, ver, formulary, options)
    release = formula.find_release(Release.new(ver))
    # todo: check installed for all required platforms
    check_dependencies formula.build_dependencies, formulary

    # really stupid hash behaviour: just Hash.new({}) does not work
    dep_dirs = Hash.new { |h, k| h[k] = Hash.new }
    Formula.full_dependencies(formulary, formula.build_dependencies).each do |f|
      options.platforms.each do |platform|
        dep = { f.name => f.release_directory(f.highest_installed_release, platform) }
        dep_dirs[platform].update dep
      end
    end

    formula.build_package release, options, dep_dirs
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
