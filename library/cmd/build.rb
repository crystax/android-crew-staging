require_relative '../exceptions.rb'
require_relative '../release.rb'
require_relative '../formulary.rb'


module Crew

  def self.build(args)
    raise NoBuildOnWindows        if Global::OS == 'windows'
    raise FormulaUnspecifiedError if args.count < 1

    formulary = Formulary.libraries

    args.each.with_index do |n, index|
      name, ver, cxver = n.split(':')
      formula = formulary[name]
      release = formula.find_release Release.new(ver, cxver)
      formula.build_package release

      puts "" if index + 1 < args.count
    end
  end
end
