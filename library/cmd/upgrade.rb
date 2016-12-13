require_relative '../exceptions.rb'
require_relative '../formulary.rb'


module Crew

  def self.upgrade(args)
    if args.length > 0
      raise CommandRequresNoArguments
    end

    formulary = Formulary.new

    names = []
    formulas = []
    formulary.each do |formula|
      if formula.installed?
        lr = formula.releases.last
        if not lr.installed? or (lr.installed_crystax_version < lr.crystax_version)
          formulas << formula
          names << last_release_name(formula)
        end
      end
    end

    if formulas.size > 0
      puts "Will install: #{names.sort.join(', ')}"
      formulas.sort { |a,b| a.name <=> b.name }.each { |formula| formula.install }
    end
  end

  # private

  def self.last_release_name(formula)
    last_release = formula.releases.last
    "#{formula.name}:#{last_release.version}:#{last_release.crystax_version}"
  end
end
