require_relative '../exceptions.rb'
require_relative '../release.rb'
require_relative '../formulary.rb'
require_relative '../build_options.rb'


module Crew

  def self.build(args)
    raise NoBuildOnWindows if Global::OS == 'windows'

    options, args = parse_args(args)
    raise FormulaUnspecifiedError if args.count < 1

    formulary = Formulary.libraries

    args.each.with_index do |n, index|
      name, ver, cxver = n.split(':')
      formula = formulary[name]
      release = formula.find_release Release.new(ver, cxver)
      raise "source code not installed for #{name}:#{release}" unless release.source_installed?

      absent = formula.dependencies.select { |d| not formulary[d.name].installed? }
      raise "uninstalled dependencies: #{absent}" unless absent.empty?

      dep_dirs = {}
      formula.full_dependencies(formulary).each { |f| dep_dirs[f.name] = f.release_directory(f.highest_installed_release) }

      formula.build_package release, options, dep_dirs

      puts "" if index + 1 < args.count
    end
  end

  def self.parse_args(args)
    opts = args.take_while { |a| a.start_with? '--' }
    args = args.drop_while { |a| a.start_with? '--' }

    [Build_options.new(opts), args]
  end
end
