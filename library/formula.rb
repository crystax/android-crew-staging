require 'uri'
require 'json'
require 'digest'
require 'fileutils'
require 'open3'
require_relative 'extend/module.rb'
require_relative 'release.rb'
require_relative 'utils.rb'
require_relative 'patch.rb'


class Formula

  PROPERTIES_FILE = 'properties.json'
  TYPE_DIR = { package: 'packages', utility: 'utilities' }


  def self.package_version(release)
    release.to_s
  end

  def self.split_package_version(pkgver)
    r = pkgver.split('_')
    raise "bad package version string: #{pkgver}" if r.size < 2
    cxver = r.pop.to_i
    ver = r.join('_')
    [ver, cxver]
  end

  def self.full_dependencies(formulary, dependencies)
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

  attr_reader :path
  attr_accessor :build_env, :num_jobs

  def initialize(path)
    @path = path
    @num_jobs = 1
    @build_env = {}
    @patches = {}
    self.class.name File.basename(@path, '.rb') unless name
  end

  def name
    self.class.name
  end

  def file_name
    File.basename(@path, '.rb')
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
      raise "bad SHA256 sum of the file #{cachepath}"
    end

    puts "unpacking archive"
    install_archive release, cachepath
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

    attr_rw :name, :desc, :homepage, :space_reqired

    attr_reader :releases, :dependencies

    def url(url = nil, &block)
      if url == nil
        [@url, @block]
      else
        @url, @block = url, block
      end
    end

    def release(r)
      raise ":version key not present in the release"         unless r.has_key?(:version)
      raise ":crystax_version key not present in the release" unless r.has_key?(:crystax_version)
      raise ":sha256 key not present in the release"          unless r.has_key?(:sha256)
      @releases = [] if !@releases
      raise "more than one version #{r[:version]}" if @releases.any? { |rel| rel.version == r[:version] }
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
    if not File.exists? propfile
      {}
    else
      JSON.parse(IO.read(propfile), symbolize_names: true)
    end
  end

  def save_properties(prop, dir)
    propfile = File.join(dir, PROPERTIES_FILE)
    File.open(propfile, "w") { |f| f.puts prop.to_json }
  end

  private

  def version_url(version)
    str, block = url
    str.gsub! '${version}', version
    if block
      br = block.call(version)
      str.gsub! '${block}', br
    end
    str
  end

  def prepare_source_code(release, dir, src_name, log_prefix)
    ver_url = version_url(release.version)
    archive = File.join(Global::CACHE_DIR, File.basename(URI.parse(ver_url).path))
    if File.exists? archive
      puts "#{log_prefix} using cached file #{archive}"
    else
      puts "#{log_prefix} downloading #{ver_url}"
      Utils.download(ver_url, archive)
    end

    # todo: handle option source_archive_without_top_dir: true
    mask = File.join(dir, '*')
    old_dir = Dir[mask]
    puts "#{log_prefix} unpacking #{File.basename(archive)} into #{dir}"
    Utils.unpack(archive, dir)
    new_dir = Dir[mask]
    diff = old_dir.empty? ? new_dir : new_dir - old_dir
    raise "source archive does not have top directory, diff: #{diff}" if diff.count != 1
    FileUtils.cd(dir) { FileUtils.mv diff[0], src_name }

    if patches(release.version).size > 0
      src_dir = File.join(dir, src_name)
      puts "#{log_prefix} patching in dir #{src_dir}"
      patches(release.version).each do |p|
        puts "#{log_prefix}   applying #{File.basename(p.path)}"
        p.apply src_dir
      end
    end
  end

  def patches(version)
    if @patches[version] == nil
      patches = []
      mask = File.join(Global::PATCHES_DIR, TYPE_DIR[type], file_name, version, '*.patch')
      Dir[mask].sort.each { |f| patches << Patch::File.new(f) }
      @patches[version] = patches
    end
    @patches[version]
  end

  def system(*args)
    cmd = args.join(' ')
    File.open(@log_file, "a") do |log|
      log.puts "== build env:"
      build_env.keys.sort.each { |k| log.puts "  #{k} = #{build_env[k]}" }
      log.puts "== cmd started:"
      log.puts "  #{cmd}"
      log.puts "=="

      status = nil
      Open3.popen2e(build_env, cmd) do |cin, cout, wt|
        cin.close
        ot = Thread.start do
          line = nil
          log.puts line while line = cout.gets
        end
        ot.join
        status = wt.value
      end
      log.puts "== cmd finished:"
      log.puts "  exit code: #{status.exitstatus} cmd: #{cmd}"
      log.puts "===="
      raise "command failed with code: #{status.exitstatus}; see #{@log_file} for details" unless status.success?
    end
  end
end
