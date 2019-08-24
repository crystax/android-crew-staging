require_relative '../exceptions.rb'
require_relative '../release.rb'
require_relative '../formulary.rb'
require_relative 'command.rb'
require_relative 'remove_source.rb'
require_relative 'source/options.rb'


module Crew

  def self.source(args)
    Source.new(args).execute
  end

  class Source < Command

    def initialize(args)
      super args, Options

      raise FormulaUnspecifiedError if args.count < 1
    end

    def execute
      args.each do |n|
        name, ver = n.split(':')
        raise "this command works only with formulas from 'target' namespace" if name.start_with?('host/')
        fqn = Formula.make_target_fqn(name)
        formula = formulary[fqn]
        releases = options.all_versions? ? formula.releases : [formula.find_release(Release.new(ver))]

        releases.each do |release|
          if release.source_installed?
            puts "sources for #{name}:#{release.version}:#{release.crystax_version} already installed"
            if options.force?
              puts "removing installed sources since --force option was specified"
              Crew.remove_source ["#{fqn}:#{release.version}"]
            else
              puts "" unless (release == releases.last) and (n == args.last)
              next
            end
          end

          formula.releases.select{ |r| r.installed? and r.version == release.version }.each do |c|
            if c.crystax_version != release.crystax_version
              raise "can't install source for #{name}:#{release} since #{c} installed"
            end
          end

          formula.install_source release, ignore_cache: options.ignore_cache?

          puts "" unless (release == releases.last) and (n == args.last)
        end
      end
    end
  end
end
