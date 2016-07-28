require_relative '../exceptions.rb'
require_relative '../release.rb'
require_relative '../formulary.rb'


module Crew

  def self.remove_source(args)
    if args.count < 1
      raise FormulaUnspecifiedError
    end

    formulary = Formulary.new

    args.each do |n|
      name, version = n.split(':')
      outname = name + (version ? ':' + version : "")

      fqn = "target/#{name}"
      formula = formulary[fqn]

      release = Release.new(version)
      raise "source code is not installed for #{outname}" if not formula.source_installed? release

      formula.releases.each { |r| formula.uninstall_source(r) if r.source_installed? and r.match?(release) }

      Dir.rmdir formula.home_directory if Dir[File.join(formula.home_directory, '*')].empty?
    end
  end
end
