require 'json'
require 'digest'
require 'fileutils'
require_relative 'extend/module.rb'
require_relative 'release.rb'
require_relative 'utils.rb'


class Formula

  PROPERTIES_FILE = 'properties.json'

  def self.package_version(release)
    release.to_s
  end

  def self.split_package_version(pkgver)
    r = pkgver.split('_')
    raise "bad package version string: #{pkgver}" if r.size < 2
    cxver = r.pop.to_i
    ver = r.join('_')
    Release.new(ver, cxver)
  end

  attr_reader :path

  def initialize(path)
    @path = path
    self.class.name File.basename(path, '.rb') unless name

    # mark installed releases
    releases.each do |r|
      dir = release_directory(r)
      if Dir.exists? dir
        prop = get_properties(dir)
        if r.crystax_version == prop[:crystax_version]
          r.update prop
        end
      end
    end
  end

  def name
    self.class.name
  end

  def desc
    self.class.desc
  end

  def homepage
    self.class.homepage
  end

  def url
    self.class.url
  end

  # NB: releases are stored in the order they're written in the formula file
  def releases
    self.class.releases
  end

  def dependencies
    self.class.dependencies ? self.class.dependencies : []
  end

  def full_dependencies(formulary)
    result = []
    deps = dependencies

    while deps.size > 0
      n = deps.first.name
      deps = deps.slice(1, deps.size)
      f = formulary[n]
      if not result.include? f
        result << f
      end
      deps += f.dependencies
    end

    result
  end

  def cache_file(release)
    File.join(Global::CACHE_DIR, archive_filename(release))
  end

  def install(r = releases.last)
    release = find_release(r)
    file = archive_filename(release)
    cachepath = File.join(Global::CACHE_DIR, file)

    if File.exists? cachepath
      puts "using cached file #{file}"
    else
      url = "#{download_base}/#{name}/#{file}"
      puts "downloading #{url}"
      Utils.download(url, cachepath)
    end

    puts "checking integrity of the archive file #{file}"
    if Digest::SHA256.hexdigest(File.read(cachepath, mode: "rb")) != sha256_sum(release)
      raise "bad SHA256 sum of the downloaded file #{cachepath}"
    end

    puts "unpacking archive"
    nstall_release_archive release, cachepath

  end

  def install_release_archive(release, archive)
    rel_dir = release_directory(release)
    prop = get_properties(rel_dir)
    install_archive release, archive
    prop.update get_properties(rel_dir)
    prop[:installed] = true
    release.installed = true
    save_properties prop, rel_dir
  end

  def installed?(release = Release.new)
    releases.any? { |r| r.match?(release) and r.installed? }
  end

  def source_installed?(release = Release.new)
    releases.any? { |r| r.match?(release) and r.source_installed? }
  end

  class Dependency

    def initialize(name, options)
      @options = options
      @options[:name] = name
    end

    def name
      @options[:name]
    end
  end

  class << self

    attr_rw :name, :desc, :homepage, :url, :space_reqired

    attr_reader :releases, :dependencies

    def release(r)
      raise ":version key not present in the release"         unless r.has_key?(:version)
      raise ":crystax_version key not present in the release" unless r.has_key?(:crystax_version)
      raise ":sha256 key not present in the release"          unless r.has_key?(:sha256)
      @releases = [] if !@releases
      @releases << Release.new(r[:version], r[:crystax_version], r[:sha256])
    end

    def depends_on(name, options = {})
      @dependencies = [] if !@dependencies
      @dependencies << Dependency.new(name, options)
    end
  end

  def to_info(formulary)
    info = "Name:        #{name}\n"     \
           "Formula:     #{path}\n"     \
           "Homepage:    #{homepage}\n" \
           "Description: #{desc}\n"     \
           "Type:        #{type}\n"     \
           "Releases:\n"
    releases.each do |r|
      installed = installed?(r) ? "installed" : ""
      info += "  #{r.version} #{r.crystax_version}  #{installed}\n"
    end
    if dependencies.size > 0
      info += "Dependencies:\n"
      dependencies.each.with_index do |d, ind|
        installed = formulary[d.name].installed? ? " (*)" : ""
        info += "  #{d.name}#{installed}"
      end
    end
    info
  end

  def find_release(release)
    rel = releases.reverse_each.find { |r| r.match?(release) }
    raise ReleaseNotFound.new(name, release) unless rel
    rel
  end

  def highest_installed_release
    rel = releases.select{ |r| r.installed? }.last
    raise "#{name} has no installed releases" if not rel
    rel
  end

  def get_properties(dir)
    propfile = File.join(dir, PROPERTIES_FILE)
    if File.exists?(propfile)
      JSON.parse(IO.read(propfile), symbolize_names: true)
    else
      {}
    end
  end

  def save_properties(prop, dir)
    propfile = File.join(dir, PROPERTIES_FILE)
    File.open(propfile, "w") { |f| f.puts prop.to_json }
  end
end
