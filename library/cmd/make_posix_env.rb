require 'fileutils'
require_relative '../formulary.rb'
require_relative 'make_posix_env_options.rb'


ETC_ENVIRONMENT_FILE_STR = <<-EOS
# This file MUST be sourced before starting to use Crystax POSIX environment
sourced=$_
top_dir=$(dirname $(dirname ${sourced}))
#echo "top_dir=$top_dir"

PATH=$top_dir/bin:$top_dir/usr/bin:$top_dir/sbin:$PATH
LD_LIBRARY_PATH=$top_dir/lib:$top_dir/usr/lib

export PATH
export LD_LIBRARY_PATH
EOS


module Crew

  DEF_PACKAGES  = ['libcrystax', 'bash', 'coreutils', 'gnu-grep', 'gnu-sed', 'gnu-which', 'gzip', 'findutils', 'less', 'xz']

  ENVIRONMENT_FILE = 'environment'

  def self.make_posix_env(args)
    options, args = MakePosixEnvOptions.parse_args(args)

    formulary = Formulary.new
    package_names = DEF_PACKAGES + options.with_packages
    packages, dependencies = packages_formulas(formulary, package_names)

    puts "create POSIX environment in: #{options.top_dir}"
    puts "for ABI:                     #{options.abi}"
    puts "packages:                    #{packages.map(&:name).join(',')}"
    puts "dependencies:                #{dependencies.map(&:name).join(',')}"

    top_dir = options.top_dir
    FileUtils.rm_rf top_dir

    puts "coping formulas:"
    (packages + dependencies).each do |formula|
      release = formula.releases.last
      puts "  #{formula.name}:#{release}"
      FileUtils.rm_rf formula.build_base_dir
      package_dir = "#{formula.build_base_dir}/#{release}/package"
      shasum = options.check_shasum? ? formula.read_shasum(release) : nil
      archive = formula.download_archive(release, nil, shasum, false)
      Utils.unpack archive, package_dir
      formula.copy_to_deb_data_dir package_dir, top_dir, options.abi
    end

    FileUtils.mkdir_p "#{top_dir}/etc"
    File.open("#{top_dir}/etc/#{ENVIRONMENT_FILE}", 'w') { |f| f.puts ETC_ENVIRONMENT_FILE_STR }

    if options.make_tarball?
      archive = "#{top_dir}.tar.bz2"
      puts "creating tarball: #{archive}"
      Utils.run_command Utils.tar_prog, '--format', 'ustar', '-C', File.dirname(top_dir), '-jcf', archive, File.basename(top_dir)
    end
  end

  def self.packages_formulas(formulary, package_names)
    packages = package_names.map { |n| "target/#{n}" }.map { |n| formulary[n] }
    deps = packages.reduce([]) { |acc, f| acc + formulary.dependencies(f) }.uniq(&:name).sort { |f1, f2| f1.name <=> f2.name }
    [packages, deps]
  end
end
