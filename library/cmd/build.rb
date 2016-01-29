require_relative '../exceptions.rb'
require_relative '../release.rb'
require_relative '../formulary.rb'
require_relative '../build_options.rb'


module Crew

  def self.build(args)
    raise NoBuildOnWindows if Global::OS == 'windows'

    options, args = parse_args(args)
    raise FormulaUnspecifiedError if args.count < 1

    libraries = Formulary.libraries
    utilities = Formulary.utilities

    args.each do |n|
      name, ver = n.split(':')

      if utilities.member? name
        formula = utilities[name]
        release = formula.find_release(Release.new(ver))
        formula.build_package release, options
      elsif libraries.member? name
        formula = libraries[name]
        release = formula.find_release(Release.new(ver))
        raise "source code not installed for #{name}:#{release}" unless release.source_installed?
        #
        absent = formula.dependencies.select { |d| not formulary[d.name].installed? }
        raise "uninstalled dependencies: #{absent.map{|d| d.name}.join(',')}" unless absent.empty?
        #
        dep_dirs = {}
        formula.full_dependencies(formulary).each { |f| dep_dirs[f.name] = f.release_directory(f.highest_installed_release) }
        #
        formula.build_package release, options, dep_dirs
      else
        raise "#{name} not found amongst utilities nor librarires"
      end

      puts "" unless n == args.last
    end
  end

  def self.parse_args(args)
    opts = args.take_while { |a| a.start_with? '--' }
    args = args.drop_while { |a| a.start_with? '--' }

    [Build_options.new(opts), args]
  end
end
