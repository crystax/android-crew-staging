require_relative '../exceptions.rb'
require_relative '../release.rb'
require_relative '../formulary.rb'
require_relative '../shasum_options.rb'


module Crew

  def self.shasum(args)
    options, args = ShasumOptions.parse_args(args)

    raise "--update option must be specified" unless options.update?

    select_formulas(args).each do |formula|
      releases = options.all_versions? ? formula.releases : [formula.releases.last]
      releases.each do |release|
        if formula.namespace == :target
          archive = File.join(Global::PKG_CACHE_DIR, formula.archive_filename(release))
          raise "archive not found: #{archive}" unless File.exist? archive
          print "#{formula.fqn} #{release}: "
          sum = Digest::SHA256.hexdigest(File.read(archive, mode: "rb"))
          if sum == release.shasum
            puts "OK"
          else
            release.shasum = sum
            formula.update_shasum(release)
            puts "updated"
          end
        else
          Platform.NAMES.each do |platform_name|
            archive = File.join(Global::PKG_CACHE_DIR, formula.archive_filename(release, platform_name))
            raise "archive not found: #{archive}" unless File.exist? archive
            print "#{formula.fqn} #{release} #{platform_name}: "
            sum = Digest::SHA256.hexdigest(File.read(archive, mode: "rb"))
            platform = Platform.new(platform_name)
            if sum == release.shasum(platform.to_sym)
              puts "OK"
            else
              release.shasum = { platform.to_sym => Digest::SHA256.hexdigest(File.read(archive, mode: "rb")) }
              update_shasum release, platform
            end
          end
        end
      end
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
