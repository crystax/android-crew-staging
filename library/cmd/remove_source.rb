require_relative '../exceptions.rb'
require_relative '../release.rb'
require_relative '../formulary.rb'
require_relative 'command.rb'


module Crew

  def self.remove_source(args)
    RemoveSource.new(args).execute
  end

  class RemoveSource < Command

    def initialize(args)
      super args
      raise FormulaUnspecifiedError if self.args.count < 1
    end

    def execute
      args.each do |n|
        name, version = n.split(':')
        raise "this command works only with formulas from 'target' namespace" if name.start_with?('host/')
        fqn = Formula.make_target_fqn(name)
        outname = name + (version ? ':' + version : "")

        formula = formulary[fqn]

        release = Release.new(version)
        raise "source code is not installed for #{outname}" if not formula.source_installed? release

        formula.releases.each { |r| formula.uninstall_source(r) if r.source_installed? and r.match?(release) }

        Dir.rmdir formula.home_directory if Dir[File.join(formula.home_directory, '*')].empty?
      end
    end
  end
end
