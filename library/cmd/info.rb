require_relative '../exceptions.rb'
require_relative '../formulary.rb'

module Crew

  def self.info(args)
    if args.count < 1
      raise FormulaUnspecifiedError
    end

    formulary = Formulary.new

    args.each.with_index do |name, index|
      formulas = formulary.find(name)
      raise FormulaUnavailableError.new(name) if formulas.size == 0
      formulas.each.with_index do |formula, num|
        print_info formula, formulary
        puts "" if num + 1 < formulas.count
      end
      puts "" if index + 1 < args.count
    end
  end

  def self.print_info(formula, formulary)
    releases = []
    formula.releases.each do |r|
      installed = formula.installed?(r) ? ' (*)' : ''
      releases << "#{r.version} #{r.crystax_version}#{installed}"
    end

    puts "Name:               #{formula.name}"
    puts "Namespace:          #{formula.namespace}"
    puts "Formula:            #{formula.path}"
    puts "Homepage:           #{formula.homepage}"
    puts "Description:        #{formula.desc}"
    puts "Class:              #{formula.class.name}"
    puts "Releases:           #{releases.join(', ')}"
    puts "Dependencies:       #{format_dependencies(formula.dependencies, formulary)}"
    puts "Build dependencies: #{format_dependencies(formula.build_dependencies, formulary)}"
  end

  def self.format_dependencies(deps, formulary)
    res = []
    deps.each do |d|
      installed = formulary[d.fqn].installed? ? ' (*)' : ''
      res << "#{d.name}#{installed}"
    end
    res.size > 0 ? res.join(', ') : 'none'
  end
end
