require_relative '../exceptions.rb'
require_relative '../formulary.rb'
require_relative 'command.rb'
require_relative 'upgrade/options.rb'


module Crew

  def self.upgrade(args)
    Upgrade.new(args).execute
  end

  class Upgrade < Command

    def initialize(args)
      super args, Options

      raise CommandRequresNoArguments if args.count > 0
    end

    UpgradeData = Struct.new(:formula, :releases)

    def execute
      upgrades = []
      formulary.each do |formula|
        if formula.installed?
          urs = formula.releases_for_upgrade
          upgrades << UpgradeData.new(formula, urs) unless urs.empty?
        end
      end

      unless upgrades.empty?
        # todo: remove sorting when formulas sorted in formulary
        names = upgrades.map { |d| n = d.formula.name; d.releases.map { |r| "#{n}:#{r}" }}.flatten
        puts "Will install: #{names.sort.join(', ')}"
        unless options.dry_run?
          upgrades.sort! { |a,b| a.formula.name <=> b.formula.name }
          upgrades.each { |data| data.releases.each { |r| data.formula.install r, check_shasum: options.check_shasum?}}
        end
      end
    end
  end
end
