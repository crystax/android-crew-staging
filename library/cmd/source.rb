require_relative '../exceptions.rb'
require_relative '../release.rb'
require_relative '../formulary.rb'
require_relative 'source_options.rb'


module Crew

  def self.source(args)
    options, args = InstallOptions.parse_args(args)
    raise FormulaUnspecifiedError if args.count < 1

    formulary = Formulary.new

    args.each do |n|
      name, ver = n.split(':')
      fqn = name.start_with?('target') ? name : "target/#{name}"
      formula = formulary[fqn]
      releases = options.all_versions? ? formula.releases : [formula.find_release(Release.new(ver))]

      releases.each do |release|
        if release.source_installed?
          puts "sources for #{name}:#{release.version}:#{release.crystax_version} already installed"
          puts "" unless (release == releases.last) and (n == args.last)
          next
        end

        formula.releases.select{ |r| r.installed? and r.version == release.version }.each do |c|
          if c.crystax_version != release.crystax_version
            raise "can't install source for #{name}:#{release} since #{c} installed"
          end
        end

        formula.install_source release

        puts "" unless (release == releases.last) and (n == args.last)
      end
    end
  end
end
