require_relative '../exceptions.rb'
require_relative '../formulary.rb'

module Crew

  def self.depends_on(args)
    raise "command requires one argument" if args.count != 1

    formulary = Formulary.new
    formula = formulary[args[0]]
    fqn = formula.fqn
    dependants = []
    formulary.each do |formula|
      if formula.dependencies.map(&:fqn).include?(fqn)
        puts formula.fqn
      end
    end
  end
end
