require_relative '../exceptions.rb'
require_relative '../release.rb'
require_relative '../formulary.rb'
require_relative '../platform.rb'
require_relative '../deb.rb'
require_relative 'command.rb'
require_relative 'make_deb/options.rb'


module Crew

  def self.make_deb(args)
    MakeDeb.new(args).execute
  end

  class MakeDeb < Command

    def initialize(args)
      super args, Options
    end

    DebInfo = Struct.new(:formula, :releases)

    def execute
      self.args = formulary.packages.map(&:name) if args.empty?

      formulas = []
      args.each do |name|
        name, version = name.split(':')
        name = Formula.make_target_fqn(name)
        formula = formulary[name]
        raise "only formulas with 'target' namespace may be packaged into deb format" if formula.namespace == :host
        releases = options.all_versions? ? formula.releases : [formula.find_release(Release.new(version))]
        formulas << DebInfo.new(formula, releases)
      end

      platform_name = nil

      formulas.each do |di|
        formula = di.formula
        puts "making packages for #{formula.name}:"
        FileUtils.rm_rf formula.build_base_dir
        di.releases.each do |release|
          base_dir = "#{formula.build_base_dir}/#{release}"
          package_dir = "#{base_dir}/package"
          FileUtils.mkdir_p package_dir
          shasum = options.check_shasum? ? formula.read_shasum(release) : nil
          archive = formula.download_archive(release, platform_name, shasum, false)
          Utils.unpack archive, package_dir
          options.abis.each do |abi|
            working_dir = "#{base_dir}/#{abi}/tmp"
            FileUtils.rm_rf working_dir
            FileUtils.mkdir_p working_dir
            puts "  #{Deb.file_name(formula.name, release, abi)}"
            Deb.make_bin_package package_dir, working_dir, abi, options.deb_repo_base, formula, release
            #Deb.make_deb_dev_package  if formula.deb_has_dev?
            FileUtils.mv Dir["#{working_dir}/*.deb"], formula.build_base_dir
          end
        end
      end
    end
  end
end
