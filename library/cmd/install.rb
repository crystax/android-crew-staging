require_relative '../exceptions.rb'
require_relative '../release.rb'
require_relative '../formulary.rb'
require_relative 'install_options.rb'


module Crew

  def self.install(args)
    options, args = InstallOptions.parse_args(args)
    raise FormulaUnspecifiedError if args.count < 1

    formulary = Formulary.new

    args.each do |n|
      name, ver = n.split(':')
      formula = formulary[name]
      releases = options.all_versions? ? formula.releases : [formula.find_release(Release.new(ver))]

      releases.each do |release|
        if release.installed?
          warning "#{name}:#{release} already installed"
          unless options.force?
            puts "" unless (release == releases.last) and (n == args.last)
            next
          end
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
          deps.each { |d| d.install d.releases.last, options.as_hash }
          puts""
        end

        formula.install release, options.as_hash

        puts "" unless (release == releases.last) and (n == args.last)
      end
    end
  end
end
