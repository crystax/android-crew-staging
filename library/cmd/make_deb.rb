require_relative '../exceptions.rb'
require_relative '../release.rb'
require_relative '../formulary.rb'
require_relative '../platform.rb'
require_relative '../deb.rb'
require_relative 'make_deb_options.rb'


module Crew

  DebInfo = Struct.new(:formula, :releases)

  def self.make_deb(args)
    options, args = MakeDebOptions.parse_args(args)

    formulary = Formulary.new

    if args.empty?
      formulas = formulary.packages
    else
      formulas = []
      args.each do |name|
        name, version = name.split(':')
        name = "target/#{name}" unless name.include? '/'
        f = formulary[name]
        raise "only formulas with 'target' namespace may be packaged into deb format" if f.namespace == :host
        if options.all_versions?
          r = f.releases
        else version
          r = [f.find_release(version)]
          formulas << DebInfo.new(f, r)
        end
      end
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
          working_dir = "#{base_dir}/#{abi}"
          FileUtils.mkdir_p working_dir
          puts "  #{formula.name}_#{release}_#{Deb.arch_for_abi(abi)}.deb"
          Deb.make_bin_package package_dir, working_dir, abi, options.deb_root_prefix, formula, release
          #Deb.make_deb_dev_package  if formula.deb_has_dev?
          FileUtils.mv Dir["#{working_dir}/*.deb"], formula.build_base_dir
        end
      end
    end
  end
end
