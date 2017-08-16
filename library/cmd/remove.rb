require_relative '../exceptions.rb'
require_relative '../release.rb'
require_relative '../formulary.rb'


module Crew

  def self.remove(args)
    if args.count < 1
      raise FormulaUnspecifiedError
    end

    formulary = Formulary.new

    args.each do |n|
      name, version = n.split(':')
      outname = name + (version ? ':' + version : "")

      formula = formulary[name]
      raise "removing of '#{name}' is not supported" unless formula.respond_to? :uninstall
      release = Release.new(version)

      if not formula.installed?(release)
        puts "#{outname} is not installed"
        next
      end

      survive_rm = formula.releases.select { |r| r.installed? and not r.match?(release) }
      ideps = formulary.dependants_of(formula.fqn).select { |d| d.installed? }
      if ideps.count > 0 and survive_rm.count == 0
        raise "#{outname} has installed dependants: #{ideps.map{|f| f.fqn}.join(', ')}"
      end

      formula.releases.each { |r| formula.uninstall(r) if r.installed? and r.match?(release) }

      if formula.has_home_directory? and Dir[File.join(formula.home_directory, '*')].empty?
        Dir.rmdir formula.home_directory
      end
    end
  end
end
