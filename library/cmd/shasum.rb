require_relative '../exceptions.rb'
require_relative '../release.rb'
require_relative '../formulary.rb'
require_relative '../platform.rb'
require_relative '../shasum_options.rb'


module Crew

  def self.shasum(args)
    options, args = ShasumOptions.parse_args(args)

    if options.update?
      select_formulas(args).each do |formula|
        releases = options.all_versions? ? formula.releases : [formula.releases.last]
        releases.each do |release|
          if formula.namespace == :target
            archive = formula.cache_file(release)
            raise "archive not found: #{archive}" unless File.exist? archive
            print "#{formula.fqn} #{release}: "
            sum = Digest::SHA256.hexdigest(File.read(archive, mode: "rb"))
            if sum == release.shasum
              puts "OK"
            else
              formula.update_shasum release
              puts "updated"
            end
          else
            options.platforms.each do |platform_name|
              # an ugly special case for windows toolbox
              # it seems that everything related to windows is ugly
              next if formula.name == 'toolbox' and not platform_name.start_with?('windows')
              #
              archive = formula.cache_file(release, platform_name)
              raise "archive not found: #{archive}" unless File.exist? archive
              print "#{formula.fqn} #{release} #{platform_name}: "
              sum = Digest::SHA256.hexdigest(File.read(archive, mode: "rb"))
              platform = Platform.new(platform_name)
              if sum == release.shasum(platform.to_sym)
                puts "OK"
              else
                formula.update_shasum release, platform
                puts "updated"
              end
            end
          end
        end
      end
    elsif options.check?
      select_formulas(args).each do |formula|
        formula.releases.each do |release|
          if formula.namespace == :target
            print "#{formula.fqn}  #{release}: "
            archive = formula.cache_file(release)
            if not File.exist? archive
              puts "archive not found"
            else
              sum = Digest::SHA256.hexdigest(File.read(archive, mode: "rb"))
              if sum == release.shasum
                puts "OK"
              else
                puts "mismatched"
              end
            end
          else
            options.platforms.each do |platform_name|
              # an ugly special case for windows toolbox
              # it seems that everything related to windows is ugly
              next if formula.name == 'toolbox' and not platform_name.start_with?('windows')
              #
              print "#{formula.fqn} #{release} #{platform_name}: "
              archive = formula.cache_file(release, platform_name)
              if not File.exist? archive
                puts "archive not found"
              else
                sum = Digest::SHA256.hexdigest(File.read(archive, mode: "rb"))
                platform = Platform.new(platform_name)
                if sum == release.shasum(platform.to_sym)
                  puts "OK"
                else
                  puts "mismatched"
                end
              end
            end
          end
        end
      end
    else
      raise "either --update or --check must be specified"
    end
  end

  def self.select_formulas(args)
    formulary = Formulary.new
    formulas = []
    if args.size == 0
      formulary.each { |f| formulas << f }
    else
      args.each { |n| formulas << formulary[n] }
    end
    formulas
  end
end
