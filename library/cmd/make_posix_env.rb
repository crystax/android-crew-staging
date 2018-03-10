# require_relative '../exceptions.rb'
# require_relative '../release.rb'
# require_relative '../platform.rb'
require 'fileutils'
require_relative '../formulary.rb'
require_relative 'make_posix_env_options.rb'


module Crew

  DEF_PACKAGES  = ['libcrystax', 'bash', 'diffutils', 'dpkg', 'apt']

  def self.make_posix_env(args)
    options, args = MakePosixEnvOptions.parse_args(args)

    formulary = Formulary.new
    formulas = packages(formulary)

    puts "create POSIX environment in: #{options.top_dir}"
    puts "for ABI:                     #{options.abi}"

    top_dir = options.top_dir
    FileUtils.rm_rf top_dir

    puts "coping formulas:"
    formulas.each do |formula|
      release = formula.releases.last
      puts "  #{formula.name}:#{release}"
      FileUtils.rm_rf formula.build_base_dir
      package_dir = "#{formula.build_base_dir}/#{release}/package"
      shasum = options.check_shasum? ? formula.read_shasum(release) : nil
      archive = formula.download_archive(release, nil, shasum, false)
      Utils.unpack archive, package_dir
      formula.copy_to_deb_data_dir package_dir, top_dir, options.abi
    end
  end

  def self.packages(formulary)
    packs = DEF_PACKAGES.map { |n| formulary[n] }
    deps = packs.reduce([]) { |acc, f| acc + formulary.dependencies(f) }
    (packs + deps).uniq(&:name).sort { |f1, f2| f1.name <=> f2.name }
  end
end
