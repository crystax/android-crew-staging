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
    puts "Name:        #{formula.name}"
    puts "Namespace:   #{formula.namespace}"
    puts "Formula:     #{formula.path}"
    puts "Homepage:    #{formula.homepage}"
    puts "Description: #{formula.desc}"
    puts "Class:       #{formula.class.name}"
    puts "Releases:"
    formula.releases.each do |r|
      installed = formula.installed?(r) ? "installed" : ""
      puts "  #{r.version} #{r.crystax_version}  #{installed}"
    end
    if formula.dependencies.size > 0
      puts "Dependencies:"
      formula.dependencies.each.with_index do |d, ind|
        installed = formulary[d.fqn].installed? ? " (*)" : ""
        puts "  #{d.name}#{installed}"
      end
    end
    if formula.build_dependencies.size > 0
      puts "Dependencies:"
      formula.build_dependencies.each.with_index do |d, ind|
        installed = formulary[d.fqn].installed? ? " (*)" : ""
        puts "  #{d.name}#{installed}"
      end
    end
  end
end
