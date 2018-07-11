require 'uri'
require 'digest'
require 'fileutils'
require 'open3'
require 'rugged'
require_relative 'extend/module.rb'
require_relative 'single_version.rb'
require_relative 'multi_version.rb'
require_relative 'release.rb'
require_relative 'utils.rb'
require_relative 'patch.rb'


class Formula

  DEF_BUILD_OPTIONS = { source_archive_without_top_dir: false }.freeze

  attr_reader :path
  attr_accessor :build_env, :num_jobs, :log_file, :system_ignore_result

  def initialize(path)
    @path = path
    fname = File.basename(@path, '.rb')
    raise "formula filename cannot contain symbol '-', use '_' instead: #{path}" if fname.include? '-'
    self.class.name fname unless name
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

  def qfn
    "#{Global::NS_DIR[namespace]}/#{File.basename(path)}"
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

  def urls
    self.class.urls
  end

  # releases are stored in the order they're written in the formula file
  def releases
    self.class.releases
  end

  def dependencies
    self.class.dependencies ? self.class.dependencies : []
  end

  def package_info
    self.class.package_info
  end

  def build_options
    self.class.build_options
  end

  def build_dependencies
    self.class.build_dependencies ? self.class.build_dependencies : []
  end

  def has_home_directory?
    false
  end

  def merge_default_install_options(opts)
    { platform: Global::PLATFORM_NAME, check_shasum: true, cache_only: false }.merge(opts)
  end

  # derived classes must define two methods in order to use install method:
  #   cache_file
  #   install_archive
  #
  def install(r = releases.last, opts = {})
    options = merge_default_install_options(opts)

    release = find_release(r)
    platform_name = options[:platform]

    cachepath = download_archive(release, platform_name, options[:check_shasum] ? read_shasum(release, platform_name) : nil, options[:cache_only])

    puts "unpacking archive"
    install_archive release, cachepath, options[:platform]
  end

  def download_archive(release, platform_name, shasum, cache_only)
    cachepath = cache_file(release, platform_name)
    archive = File.basename(cachepath)

    if File.exists? cachepath
      puts "using cached file #{archive}"
    else
      raise "#{archive} not found in the packages cache #{Global.pkg_cache_dir(self)}" if cache_only
      # GitHub release assets feature does not support sub-folders
      # that is a packages/libjpeg-9b_1.tag.xz will be stored as packages.libjpeg-9b_1.tag.xz
      sep = (Global::DOWNLOAD_BASE == GitHub::STAGING_DOWNLOAD_BASE) ? '.' : '/'
      url = "#{Global::DOWNLOAD_BASE}/#{Global::NS_DIR[namespace]}#{sep}#{archive}"
      puts "downloading #{url}"
      Utils.download(url, cachepath)
    end

    if not shasum
      puts "skipping integrity check of the archive file #{archive}"
    else
      puts "checking integrity of the archive file #{archive}"
      raise "bad SHA256 sum of the file #{cachepath}" if Digest::SHA256.hexdigest(File.read(cachepath, mode: "rb")) != shasum
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

  def build_filelist?
    self.class.build_filelist
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

    def version
      @options[:version]
    end
  end

  class << self

    attr_rw :name, :desc, :homepage, :namespace, :build_filelist
    attr_reader :urls, :releases, :dependencies, :build_dependencies

    # called when self inherited by subclass
    def inherited(subclass)
      subclass.namespace self.namespace
      subclass.build_filelist self.build_filelist
    end

    def url(url, &block)
      @urls ||= []
      @urls << [url, block]
    end

    def release(ver, options = {})
      r = { version: ver }
      r[:crystax_version] = options.has_key?(:crystax) ? options[:crystax] : 1

      raise "#{name}: wrong crystax version: #{r[:crystax_version].inspect}" unless r[:crystax_version].is_a?(Integer) && r[:crystax_version] > 0

      @releases = [] if !@releases
      raise "#{name}: has more than one version #{r[:version]}" if @releases.any? { |rel| rel.version == r[:version] }

      @releases << Release.new(r[:version], r[:crystax_version])
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
      nm, ns = parse_name(name)
      deps << Dependency.new(nm, ns, options)
    end

    def package_info(hash = nil)
      @package_info = { root_dir: [] } unless @package_info
      @package_info.update hash if hash
      @package_info
    end

    def build_options(hash = nil)
      @build_options = self::DEF_BUILD_OPTIONS.dup unless @build_options
      @build_options.update hash if hash
      @build_options
    end
  end

  def self.parse_name(name)
    nm, ns = name.split('/')
    if not ns
      ns = namespace
    elsif
      ns = ns.to_sym
      raise "bad namespace: #{ns}" unless [:host, :target].include? ns
    end
    [nm, ns]
  end

  def replace_lines_in_file(file)
    content = []
    replaced = 0
    File.read(file).split("\n").each do |l1|
      l2 = yield(l1)
      replaced += 1 if l1 != l2
      content << l2
    end

    raise "no  line was replaced in #{file}" unless replaced > 0

    File.open(file, 'w') { |f| f.puts content }

    replaced
  end


  private


  def expand_url(url, release)
    url_str, block = url
    str = url_str.dup
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

  def self.src_cache_file(formula_name, release, url)
    url_file = File.basename(URI.parse(url).path)
    a = url_file.split('.')
    if a.size == 1
      ext = ''
    else
      ext = a[-1]
      ext = 'tar.' + ext if a[-2] == 'tar'
    end
    file = "#{formula_name}-#{release.version}.#{ext}"
    File.join(Global::SRC_CACHE_DIR, file)
  end

  def src_cache_file(release, url)
    Formula.src_cache_file(file_name, release, url)
  end

  def prepare_source_code(release, dir, src_name, log_prefix)
    urls.each do |url|
      begin
        eurl = expand_url(url, release)
        src_dir = File.join(dir, src_name)
        if git_repo_spec? eurl
          git_url, git_ref, ref_type = parse_git_url(eurl)
          # puts "git_url:  #{git_url}"
          # puts "git_ref:  #{git_ref}"
          # puts "ref_type: #{ref_type}"

          repo = Rugged::Repository.clone_at(git_url, src_dir, credentials: Utils.make_git_credentials(git_url))

          sha1 = case ref_type
                 when :commit
                   git_ref
                 when :tag
                   repo.tags[git_ref].peel
                 when :ref
                   object = repo.lookup(repo.rev_parse_oid(git_ref))
                   case object
                   when Rugged::Tag, Rugged::Tag::Annotation
                     repo.tags[object.name].peel
                   when Rugged::Commit
                     object.oid
                   else
                     raise "unsupported ref type: #{object.class}"
                   end
                 else
                   raise "unsupported ref type: #{ref_type}"
                 end

          repo.checkout sha1, strategy: :force
          repo.close
          FileUtils.rm_rf File.join(src_dir, '.git')
        else
          archive = src_cache_file(release, eurl)
          if File.exist? archive
            puts "#{log_prefix} using cached file #{archive}"
          else
            puts "#{log_prefix} downloading #{eurl}"
            Utils.download(eurl, archive)
          end

          if build_options[:source_archive_without_top_dir]
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
        end

        if patches(release.version).size > 0
          puts "#{log_prefix} patching in dir #{src_dir}"
          patches(release.version).each do |p|
            puts "#{log_prefix}   applying #{File.basename(p.path)}"
            p.apply src_dir
          end
        end
      rescue Exception => e
        warning "failed to handle #{eurl}; reason: #{e}"
      else
        # here is the point of the normal exit
        FileUtils.touch Dir["#{src_dir}/**/*"], mtime: Time.now
        return
      end
    end
    raise
  end

  def git_repo_spec?(uri)
    uri =~ /\|(commit|tag|ref):/
  end

  def parse_git_url(uri)
    url, ref = uri.split('|')
    type, ref = ref.split(':')
    case type
    when 'commit', 'tag', 'ref'
      type = type.to_sym
    else
      raise "unsupported git ref type: #{type}"
    end
    [url, ref, type]
  end

  def build_log_print(msg)
    File.open(@log_file, "a") { |log| log.print msg }
    print msg
  end

  def build_log_puts(msg)
    File.open(@log_file, "a") { |log| log.puts msg }
    puts msg
  end

  public

  def system(*args)
    cmd = args.join(' ')
    File.open(@log_file, "a") do |log|
      log.sync = true
      log.puts "== build env:"
      build_env.keys.sort.each { |k| log.puts "  #{k} = #{build_env[k]}" }
      log.puts "== cmd started:"
      log.puts "  #{cmd}"
      log.puts "=="

      status = nil
      Open3.popen2e(build_env, cmd) do |cin, cout, wt|
      # args = args.map { |a| a.to_s }
      # Open3.popen2e(build_env, *args) do |cin, cout, wt|
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
