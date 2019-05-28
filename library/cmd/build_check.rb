require_relative '../exceptions.rb'
require_relative '../release.rb'
require_relative '../utils.rb'
require_relative 'command.rb'
require_relative 'build_check/options.rb'


module Crew

  def self.build_check(args)
    BuildCheck.new(args).execute
  end

  class BuildCheck < Command

    def initialize(args)
      super args, Options
    end

    def execute
      formulas.each do |formula|
        io = StringIO.new
        have_issues = false
        io.puts "#{formula.fqn}: "
        formula.releases.each do |release|
          io.print "  #{release}: "
          unless release.installed?
            io.puts 'not installed'
          else
            bad_names = []
            bad_releases = []
            newer_releases = []
            formula.build_info(release).each do |bi_str|
              # puts "bi_str: #{bi_str}"
              bi_fqn, bi_release = parse_build_info(bi_str)
              # puts "bi_fqn: #{bi_fqn}"
              # puts "bi_release: #{bi_release}"
              begin
                bi_formula = formulary[bi_fqn]
                # puts "  bi_release 1: #{bi_release}"
                bi_release = bi_formula.find_exact_release(bi_release)
                # puts "  bi_release 2: #{bi_release}"
                formula.dependencies.select { |d| d.fqn == bi_formula.fqn }.each do |dep|
                  if dep.version
                    last = bi_formula.find_matched_releases(dep.version).first
                  else
                    last = bi_formula.releases.last
                  end

                  unless (last.version == bi_release.version) && (last.crystax_version == bi_release.crystax_version)
                    newer_releases << bi_str
                  end
                end
              rescue FormulaUnavailableError
                bad_names << bi_str
              rescue ReleaseNotFound
                bad_releases << bi_str
              end
            end
            if bad_names.empty? && bad_releases.empty? && newer_releases.empty?
              io.puts 'OK'
            else
              have_issues = true
              io.puts 'build with bad build dependencies:'
              io.puts "    not existing formulas: #{bad_names.join(', ')}" unless bad_names.empty?
              io.puts "    not existing releases: #{bad_releases.join(', ')}" unless bad_releases.empty?
              io.puts "    have newer releases: #{newer_releases.join(', ')}" unless newer_releases.empty?
            end
          end
        end
        puts io.string if !options.show_bad_only? || have_issues
      end
    end

    private

    def formulas
      if args.empty?
        formulary.tools + formulary.packages
      else
        ff = []
        args.each { |name| ff << formulary.find(name) }
        ff.flatten
      end
    end

    def parse_build_info(bi_str)
      name, rel_str = bi_str.split(':')
      ver, cx_ver = Utils.split_package_version(rel_str)
      release = Release.new(ver, cx_ver)
      [name, release]
    end
  end
end
