require_relative '../exceptions.rb'
require_relative '../release.rb'
require_relative '../formulary.rb'


module Crew

  def self.install(args)
    if args.count < 1
      raise FormulaUnspecifiedError
    end

    formulary = Formulary.libraries

    args.each.with_index do |n, index|
      name, ver = n.split(':')
      formula = formulary[name]
      release = formula.find_release(Release.new(ver))

      if release.installed?
        puts "#{name}:#{release} already installed"
        next
      end

      formula.releases.select { |r| r.source_installed? and r.version == release.version }.each do |c|
        if c.crystax_version != release.crystax_version
          raise "can't install #{name}:#{release} since sources for #{c} installed"
        end
      end

      puts "calculating dependencies for #{name}: "
      deps = formula.full_dependencies(formulary).select { |d| not d.installed? }
      puts "  dependencies to install: #{(deps.map { |d| d.name }).join(', ')}"

      if deps.count > 0
        puts "installing dependencies for #{name}:"
        deps.each { |d| d.install }
        puts""
      end

      formula.install release

      puts "" if index + 1 < args.count
    end
  end
end
