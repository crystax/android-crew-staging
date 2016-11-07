require_relative '../exceptions.rb'
require_relative '../release.rb'
require_relative '../formulary.rb'
require_relative '../install_options.rb'


module Crew

  def self.install(args)
    options, args = InstallOptions.parse_args(args)
    raise FormulaUnspecifiedError if args.count < 1

    formulary = Formulary.new

    args.each.with_index do |n, index|
      name, ver = n.split(':')
      fqns = formulary.find(name)
      raise "packages present in more than one namespace: #{fqns.map(&:fqn)}; please, specify required namespace" if fqns.size > 1
      raise "#{name} not found" if fqns.size == 0
      formula = fqns[0]
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

      # todo: handle build dependencies too?
      puts "calculating dependencies for #{name}: "
      deps = formulary.dependencies(formula).select { |d| not d.installed? }
      puts "  dependencies to install: #{(deps.map { |d| d.name }).join(', ')}"

      if deps.count > 0
        puts "installing dependencies for #{name}:"
        deps.each { |d| d.install d.releases.last, platform: options.platform, check_shasum: options.check_shasum? }
        puts""
      end

      formula.install release, platform: options.platform, check_shasum: options.check_shasum?

      puts "" if index + 1 < args.count
    end
  end
end
