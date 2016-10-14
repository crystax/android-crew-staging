require 'uri'
require 'digest'
require 'fileutils'
require 'open3'
require 'rugged'
require_relative 'extend/module.rb'
require_relative 'release.rb'
require_relative 'utils.rb'
require_relative 'patch.rb'


class Formula

  DEF_BUILD_OPTIONS = { source_archive_without_top_dir: false }.freeze

  attr_reader :path
  attr_accessor :build_env, :num_jobs, :log_file, :system_ignore_result

  def initialize(path)
    @path = path
    self.class.name File.basename(@path, '.rb') unless name
    # build releated stuff
    @num_jobs = 1
    @build_env = {}
    @patches = {}
    @log_file = File.join('/tmp', name)
    @system_ignore_result = false
  end

  def name
    self.class.name
  end

  def namespace
    self.class.namespace
  end

  def fqn
    "#{namespace}/#{name}"
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

  # releases are stored in the order they're written in the formula file
  def releases
    self.class.releases
  end

  def dependencies
    self.class.dependencies ? self.class.dependencies : []
  end

  def build_options
    self.class.build_options
  end

  def build_dependencies
    self.class.build_dependencies ? self.class.build_dependencies : []
  end

  def cache_file(release)
    File.join(Global::CACHE_DIR, archive_filename(release))
  end

  def download_archive(archive, shasum)
    cachepath = File.join(Global::CACHE_DIR, archive)

    if File.exists? cachepath
      puts "using cached file #{archive}"
    else
      url = "#{Global::DOWNLOAD_BASE}/#{Global::NS_DIR[namespace]}/#{file_name}/#{archive}"
      puts "downloading #{url}"
      Utils.download(url, cachepath)
    end

    puts "checking integrity of the archive file #{archive}"
    if Digest::SHA256.hexdigest(File.read(cachepath, mode: "rb")) != shasum
      raise "bad SHA256 sum of the file #{cachepath}"
    end

    cachepath
  end

  def installed?(release = Release.new)
    releases.any? { |r| r.match?(release) and r.installed? }
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

  class Dependency

    def initialize(name, ns, options)
      @options = options
      @options[:name] = name
      @options[:ns] = ns
    end

    def name
      @options[:name]
    end

    def namespace
      @options[:ns]
    end

    def fqn
      "#{@options[:ns]}/#{@options[:name]}"
    end
  end

  class << self

    attr_rw :name, :desc, :homepage, :namespace
    attr_reader :releases, :dependencies, :build_dependencies

    # called when self inherited by subclass
    def inherited(subclass)
      subclass.namespace self.namespace
    end

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
      @dependencies ||= []
      add_dependency(name, options, @dependencies)
    end

    def build_depends_on(name, options = {})
      @build_dependencies ||= []
      add_dependency(name, options, @build_dependencies)
    end

    def add_dependency(name, options, deps)
      deps = [] if !deps
      ns = options.delete(:ns)
      if not ns
        ns = namespace
      elsif ns.class == String
        ns = ns.to_sym
      end
      deps << Dependency.new(name, ns, options)
    end

    def build_options(hash = nil)
      @build_options = self::DEF_BUILD_OPTIONS.dup unless @build_options
      @build_options.update hash if hash
      @build_options
    end
  end

  private

  def expand_url(release)
    str, block = url
    str.gsub! '${version}', release.version
    str.gsub! '${crystax_version}', release.crystax_version.to_s
    if block
      br = block.call(release)
      str.gsub! '${block}', br
    end
    str
  end

  def patches(version)
    if @patches[version] == nil
      patches = []
      mask = File.join(Global::PATCHES_DIR, Global::NS_DIR[namespace], file_name, version, '*.patch')
      Dir[mask].sort.each { |f| patches << Patch::File.new(f) }
      @patches[version] = patches
    end
    @patches[version]
  end

  def prepare_source_code(release, dir, src_name, log_prefix)
    eurl = expand_url(release)
    if git_repo_spec? eurl
      git_url = ''
      git_tag = ''
      eurl.each do |e|
        if e.start_with? 'git_tag:'
          git_tag = e.split(':')[1]
        else
          git_url = e
        end
      end
      # todo: checkout he specified tag
      puts "git_url: #{git_url}"
      repo = Rugged::Repository.clone_at(git_url, dir)
    else
      archive = File.join(Global::CACHE_DIR, File.basename(URI.parse(eurl).path))
      if File.exists? archive
        puts "#{log_prefix} using cached file #{archive}"
      else
        puts "#{log_prefix} downloading #{eurl}"
        Utils.download(eurl, archive)
      end

      if build_options[:source_archive_without_top_dir]
        src_dir = File.join(dir, src_name)
        FileUtils.mkdir_p src_dir
        puts "#{log_prefix} unpacking #{File.basename(archive)} into #{src_dir}"
        Utils.unpack(archive, src_dir)
      else
        mask = File.join(dir, '*')
        old_dir = Dir[mask]
        puts "#{log_prefix} unpacking #{File.basename(archive)} into #{dir}"
        Utils.unpack(archive, dir)
        new_dir = Dir[mask]
        diff = old_dir.empty? ? new_dir : new_dir - old_dir
        raise "source archive does not have top directory, diff: #{diff}" if diff.count != 1
        FileUtils.cd(dir) { FileUtils.mv diff[0], src_name }
      end

      if patches(release.version).size > 0
        src_dir = File.join(dir, src_name)
        puts "#{log_prefix} patching in dir #{src_dir}"
        patches(release.version).each do |p|
          puts "#{log_prefix}   applying #{File.basename(p.path)}"
          p.apply src_dir
        end
      end
    end
  end

  def git_repo_spec?(uri)
    uri =~ /\|git_tag:/
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
      raise "command failed with code: #{status.exitstatus}; see #{@log_file} for details" unless status.success? or self.system_ignore_result
    end
  end
end
