require_relative '../exceptions.rb'
require_relative '../release.rb'
require_relative '../formulary.rb'


module Crew

  def self.source(args)
    if args.count < 1
      raise FormulaUnspecifiedError
    end

    formulary = Formulary.new

    args.each do |n|
      name, ver = n.split(':')
      fqn = name.start_with?('target') ? name : "target/#{name}"
      formula = formulary[fqn]
      release = formula.find_release Release.new(ver)

      if release.source_installed?
        puts "sources for #{name}:#{release.version}:#{release.crystax_version} already installed"
        next
      end

      formula.releases.select{ |r| r.installed? and r.version == release.version }.each do |c|
        if c.crystax_version != release.crystax_version
          raise "can't install source for #{name}:#{release} since #{c} installed"
        end
      end

      formula.install_source release

      puts "" unless n == args.last
    end
  end
end
