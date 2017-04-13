require_relative '../release.rb'
require_relative '../formulary.rb'
require_relative '../platform.rb'
require_relative '../show_outdated_options.rb'


module Crew

  def self.show_outdated(args)
    options, args = ShowOutdatedOptions.parse_args(args)

    win_platforms = [Platform.new('windows-x86_64'), Platform.new('windows')]
    std_platforms = (Global::OS == 'darwin') ? [Platform.new('darwin-x86_64')] : [Platform.new('linux-x86_64')] + win_platforms

    Formulary.new.select(args).each do |formula|
      releases = options.all_versions? ? formula.releases : [formula.releases.last]
      reason = nil
      # todo: add supported platforms to formula class?
      if formula.namespace == :target
        needs_rebuild = releases.any? do |release|
          archive = formula.cache_file(release)
          if not File.exist? archive
            reason = 'no archive'
            true
          elsif File.ctime(formula.path) > File.ctime(archive)
            reason = 'outdated'
            true
          # elsif Digest::SHA256.hexdigest(File.read(archive, mode: "rb")) != release.shasum
          #   reason = 'SHA256 mismatch'
          #   true
          else
            false
          end
        end
      else
        platforms = std_platforms
        platforms = (Global::OS == 'linux') ? win_platforms : [] if formula.name.end_with?('toolbox')
        needs_rebuild = releases.any? do |release|
          platforms.any? do |platform|
            archive = formula.cache_file(release, platform.name)
            if not File.exist? archive
              reason = 'no archive'
              true
            elsif File.ctime(formula.path) > File.ctime(archive)
              reason = 'outdated'
              true
            # elsif Digest::SHA256.hexdigest(File.read(archive, mode: "rb")) != release.shasum(platform.to_sym)
            #   reason = 'SHA256 mismatch'
            #   true
            else
              false
            end
          end
        end
      end
      # we need to output versions here because we use them in the Rakefile
      puts "#{formula.fqn}: #{formula.qfn}: #{releases.map(&:to_s).join(',')}: #{reason}" if needs_rebuild
    end
  end
end
