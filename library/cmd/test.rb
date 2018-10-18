require_relative '../exceptions.rb'
require_relative '../release.rb'
require_relative '../formulary.rb'
require_relative 'test/options.rb'


module Crew

  def self.test(args)
    Test.new(args).execute
  end

  class Test

    attr_reader :options, :formulary, :args

    def initialize(args)
      @formulary = Formulary.new
      @options, @args = Options.parse_args(args)
    end

    def execute
      args.each do |n|
        item, ver = n.split(':')
        formula = formulary[item]
        unless formula.support_testing?
          raise "formula #{formula.name} does not support testing"
        else
          releases = options.all_versions? ? formula.releases : [formula.find_release(Release.new(ver))]
          releases.each do |release|
            raise "#{formula.name}:#{release} is not installed" unless release.installed?
            tests_dir = formula.test_directory(release)
            raise "#{formula.name}:#{release} has no tests" unless Dir.exist?(tests_dir) && !Dir.empty?(tests_dir)
            formula.test release, options
          end
        end
      end
    end
  end
end
