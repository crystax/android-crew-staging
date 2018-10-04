require 'pathname'
require 'open3'
require 'socket'
require 'rugged'
require 'digest'
require 'find'
require_relative '../library/release.rb'
require_relative '../library/utility.rb'
require_relative 'spec_consts.rb'
require_relative Crew::Test::UTILS_RELEASES_FILE

module Spec

  module Helpers

    class CrewFailed < RuntimeError

      def initialize(cmd, exitcode, err)
        @cmd = cmd
        @exitcode = exitcode
        @err = err
      end

      def to_s
        "failed crew command: #{@cmd}\n"
        "  exit code: #{@exitcode}\n"
        "  error output: #{@err}\n"
      end
    end

    class Repository

      def self.init_at(dir)
        repo = Rugged::Repository.init_at dir
        repo.config['user.email'] = 'crew-test@crystax.net'
        repo.config['user.name'] = 'Crew Test'
        repo.close
        Repository.new dir
      end

      def self.clone_at(url, local_path, options = {})
        local_path = local_path.gsub('/', '\\') if Global::OS == 'windows'
        repo = Rugged::Repository.clone_at(url, local_path, options)
        repo.close
        Repository.new local_path
      end

      def initialize(dir)
        @repo = Rugged::Repository.new dir
        @repo.checkout 'refs/heads/master' unless @repo.head_unborn?
      end

      def remotes
        @repo.remotes
      end

      def add(file)
        @repo.index.add file
        # @repo.index.add path: file,
        #                 oid: Rugged::Blob.from_workdir(@repo, file),
        #                 mode: 0100644
      end

      def remove(file)
        @repo.index.remove file
      end

      def commit(message)
        commit = @repo.index.write_tree @repo
        @repo.index.write
        Rugged::Commit.create @repo,
                              message: message,
                              parents: @repo.head_unborn? ? [] : [@repo.head.target],
                              tree: commit,
                              update_ref: 'HEAD'
      end

      def push(options)
        @repo.remotes['origin'].push ['refs/heads/master'], options
      end

      def close
        @repo.close
        @repo = nil
      end
    end

    attr_reader :command, :out, :err, :exitstatus

    def crew(*params)
      crewbin = Pathname.new(File.dirname(__FILE__)).parent.join('crew')
      run_command("#{crewbin} -b #{params.join(' ')}")
    end

    def crew_checked(*params)
      crew(*params)
      raise CrewFailed.new(command, exitstatus, err) if exitstatus != 0 or err != ''
    end

    def crew_update_shasum(base_dir)
      old_base = ENV['CREW_BASE_DIR']
      old_pkg  = ENV['CREW_PKG_CACHE_DIR']

      ENV['CREW_BASE_DIR']      = base_dir
      ENV['CREW_PKG_CACHE_DIR'] = Pathname.new(Crew::Test::WWW_DIR).realpath.to_s

      crew 'shasum', '--update'

      ENV['CREW_BASE_DIR']      = old_base
      ENV['CREW_PKG_CACHE_DIR'] = old_pkg

      raise CrewFailed.new(command, exitstatus, err) if exitstatus != 0 or err != ''
    end

    def run_command(cmd)
      @command = cmd
      @out = ''
      @err = ''
      @exitstatus = nil

      Open3.popen3(cmd) do |_, stdout, stderr, waitthr|
        ot = Thread.start do
          while c = stdout.getc
            @out += "#{c}"
          end
        end

        et = Thread.start do
          while c = stderr.getc
            @err += "#{c}"
          end
        end

        ot.join
        et.join

        @exitstatus = waitthr && waitthr.value.exitstatus
      end
    end

    def result
      (exitstatus == 0 and err == '') ? :ok : [exitstatus, err]
    end

    def environment_init
      ENV['CREW_DOWNLOAD_BASE'] = Crew::Test::DOWNLOAD_BASE
      ENV['CREW_BASE_DIR']      = "#{File.dirname(__FILE__)}/#{Crew::Test::CREW_DIR}"
      ENV['CREW_NDK_DIR']       = "#{File.dirname(__FILE__)}/#{Crew::Test::NDK_DIR}"
      ENV['CREW_PKG_CACHE_DIR'] = "#{File.dirname(__FILE__)}/#{Crew::Test::PKG_CACHE_DIR}"
    end

    def origin_url
      config = Rugged::Config.new('./crew/.git/config')
      config['remote.origin.url']
    end

    def set_origin_url(url)
      config = Rugged::Config.new('./crew/.git/config')
      config['remote.origin.url'] = url
    end

    def package_archive_name(name, release)
      archive_name(:target, name, release.version, release.crystax_version)
    end

    def tool_archive_name(name, release)
      archive_name(:host, name, release.version, release.crystax_version)
    end

    def archive_name(type, name, version, cxver, platform_name = Global::PLATFORM_NAME)
      suffix = case type
               when :target
                 ''
               when :host
                 "-#{platform_name}"
               else
                 raise "bad archive type #{type}"
               end
      "#{name}-#{version}_#{cxver}#{suffix}.#{Global::ARCH_EXT}"
    end

    def pkg_cache_path_in(type, filename)
      File.join(Global::PKG_CACHE_DIR, Global::NS_DIR[type], filename)
    end

    def pkg_cache_has_package?(name, release)
      pkg_cache_in? :target, name, release.version, release.crystax_version
    end

    def pkg_cache_has_tool?(name, release)
      pkg_cache_in? :host, name, release.version, release.crystax_version
    end

    def pkg_cache_in?(type, name, version, cxver)
      File.exists?(File.join(Global::PKG_CACHE_DIR, Global::NS_DIR[type], archive_name(type, name, version, cxver)))
    end

    def pkg_cache_empty?(type = nil)
      if type
        Dir[File.join(Global::PKG_CACHE_DIR, Global::NS_DIR[type], '*')].empty?
      else
        tools_dir = File.join(Global::PKG_CACHE_DIR, Global::NS_DIR[:host])
        packages_dir = File.join(Global::PKG_CACHE_DIR, Global::NS_DIR[:target])
        Dir["#{tools_dir}/*"].empty? and Dir["#{packages_dir}/*"].empty?
      end
    end

    def pkg_cache_add_file(type, filename, rel)
      archive = File.join(Crew::Test::DOCROOT_DIR, Global::NS_DIR[type], archive_name(type, filename, rel.version, rel.crystax_version))
      FileUtils.cp archive, File.join(Global::PKG_CACHE_DIR, Global::NS_DIR[type])
    end

    def pkg_cache_del_file(type, filename, rel)
      FileUtils.rm File.join(Global::PKG_CACHE_DIR, Global::NS_DIR[type], archive_name(type, filename, rel.version, rel.crystax_version))
    end

    def pkg_cache_corrupt_file(type, filename, rel)
      archive = pkg_cache_path_in(type, archive_name(type, filename, rel.version, rel.crystax_version))
      file_size = File.size(archive)
      pos = Random.rand(file_size)
      block = Random::DEFAULT.bytes([1, Random.rand(file_size - pos)].max)
      File.open(archive, 'r+') do |f|
        f.seek pos
        f.write block
      end
    end

    def pkg_cache_add_tool(filename, opts = {})
      options = { release: nil, update: true }
      options.update opts
      options[:release] ||= Crew::Test::UTILS_RELEASES[filename][0]
      pkg_cache_add_file :host, filename, options[:release]
      crew_checked 'shasum', '--update', filename if options[:update]
      options[:release]
    end

    def pkg_cache_add_with_formula(type, filename, opts)
      options = { release: nil, update: true, delete: false }
      options.update opts
      options[:release] ||= formula_most_recent_release(filename)
      copy_formulas type, "#{filename}.rb"
      pkg_cache_add_file type, filename, options[:release]
      crew_checked 'shasum', '--update', filename          if options[:update]
      pkg_cache_del_file type, filename, options[:release] if options[:delete]
      options[:release]
    end

    def pkg_cache_add_package_with_formula(filename, options = {})
      pkg_cache_add_with_formula :target, filename, options
    end

    def pkg_cache_add_tool_with_formula(filename, options = {})
      pkg_cache_add_with_formula :host, filename, options
    end

    def pkg_cache_add_all_tools(opts = {})
      options = { update: true }
      options.update opts
      FileUtils.cp Dir["#{Crew::Test::DOCROOT_DIR}/#{Global::NS_DIR[:host]}/*"], "#{Global::PKG_CACHE_DIR}/#{Global::NS_DIR[:host]}"
      crew_checked 'shasum', '--update' if options[:update]
    end

    def pkg_cache_clean
      #File.open('/tmp/crew.log', 'a') { |f| f.puts "DEBUG: pkg_cache_clean: #{Global::PKG_CACHE_DIR}" }
      FileUtils.rm_rf   Global::PKG_CACHE_DIR
      FileUtils.mkdir_p Global::NS_DIR.values.map { |d| File.join(Global::PKG_CACHE_DIR, d) }
    end

    def src_cache_clean
      #File.open('/tmp/crew.log', 'a') { |f| f.puts "DEBUG: src_cache_clean: #{Global::SRC_CACHE_DIR}" }
      FileUtils.rm_rf   Global::SRC_CACHE_DIR
      FileUtils.mkdir_p Global::SRC_CACHE_DIR
    end

    def clean_cache
      pkg_cache_clean
      src_cache_clean
    end

    def clean_hold
      #File.open('/tmp/crew.log', 'a') { |f| f.puts "DEBUG: clean_hold: #{Global::HOLD_DIR}" }
      FileUtils.rm_rf   Global::HOLD_DIR
      FileUtils.mkdir_p Global::HOLD_DIR
    end

    def clean_utilities
      orig_tools_dir = File.join(Crew::Test::NDK_COPY_DIR, 'prebuilt', Global::PLATFORM_NAME)
      tools_dir      = File.join(Crew::Test::NDK_DIR,      'prebuilt', Global::PLATFORM_NAME)
      FileUtils.rm_rf tools_dir
      FileUtils.cp_r orig_tools_dir, File.dirname(tools_dir)
      Crew::Test::UTILS_FILES.each do |util|
        FileUtils.rm_rf File.join(Crew::Test::NDK_DIR, '.crew', util)
        FileUtils.cp_r File.join(Crew::Test::NDK_COPY_DIR, '.crew', util), File.join(Crew::Test::NDK_DIR, '.crew')
      end
    end

    def copy_formulas(type, *names)
      names.each do |n|
        FileUtils.cp File.join('data', n), File.join(Global::FORMULA_DIR, Global::NS_DIR[type])
      end
    end

    def copy_package_formulas(*names)
      copy_formulas :target, *names
    end

    def ndk_init
      #File.open('/tmp/crew.log', 'a') { |f| f.puts "DEBUG: ndk_init: NDK_DIR: #{Crew::Test::NDK_DIR}" }
      FileUtils.rm_rf Crew::Test::NDK_DIR
      FileUtils.cp_r Crew::Test::NDK_COPY_DIR, Crew::Test::NDK_DIR
    end

    def repository_init
      #File.open('/tmp/crew.log', 'a') { |f| f.puts "DEBUG: repository_init at: #{origin_dir}" }
      FileUtils.rm_rf origin_dir
      repo = Repository.init_at origin_dir
      repository_add_initial_files origin_dir, repo
      repo.close
    end

    def repository_clone
      #File.open('/tmp/crew.log', 'a') { |f| f.puts "DEBUG: repository_clone at: #{Global::BASE_DIR}" }
      FileUtils.rm_rf Global::BASE_DIR
      Repository.clone_at(origin_dir, Global::BASE_DIR).close
    end

    TEST_REPO_GIT_URL   = 'git@github.com:crystaxnet/crew-test.git'
    TEST_REPO_HTTPS_URL = 'https://github.com/crystaxnet/crew-test.git'

    def repository_network_init
      # clone network repository, clean it and push back
      FileUtils.rm_rf net_origin_dir
      repo = Repository.clone_at(TEST_REPO_GIT_URL, net_origin_dir, credentials: ssl_key)
      Find.find("#{net_origin_dir}/formula") do |f|
        if File.file?(f)
          File.unlink f
          repo.remove(f.gsub("#{net_origin_dir}/", ''))
        end
      end
      repo.commit "clean repository"
      repo.push credentials: ssl_key
      # add new files to the repository and push changes
      repository_add_initial_files net_origin_dir, repo
      repo.push credentials: ssl_key
      repo.close
    end

    def repository_network_clone
      FileUtils.rm_rf Global::BASE_DIR
      Repository.clone_at(TEST_REPO_HTTPS_URL, Global::BASE_DIR).close
    end

    def repository_change_crew_script
      data_dir = Pathname.new(Crew::Test::DATA_DIR).realpath.to_s
      FileUtils.cp "#{data_dir}/crew.new", "#{origin_dir}/crew"
      repo = Repository.new origin_dir
      repo.add 'crew'
      repo.commit 'change crew script'
      repo.close
    end

    def repository_add_formula(ns, *names)
      dir = File.join('formula', Global::NS_DIR[ns])
      repo = Repository.new origin_dir
      names.each do |n|
        a = n.split(':')
        if a.size == 1
          dst = src = a[0]
        else
          src = a[0]
          dst = a[1]
        end
        file = File.join(dir, dst)
        FileUtils.cp File.join('data', src), File.join(origin_dir, file)
        repo.add file
      end
      crew_update_shasum origin_dir
      repo.add 'etc/shasums.txt'
      repo.commit "add_#{names.join('_')}"
    end

    def repository_del_formula(ns, *names)
      repo = Repository.new origin_dir
      dir = File.join('formula', Global::NS_DIR[ns])
      names.each { |n| repo.remove File.join(dir, n) }
      repo.commit "del_#{names.join('_')}"
    end

    def formula_most_recent_release(filename)
      lines = []
      path = "#{Crew::Test::DATA_DIR}/#{filename}.rb"
      File.foreach(path) { |l| lines << l if l =~ /^[[:space:]]*release[[:space:]]'/ }
      raise "bad formulas syntax #{filename}: no release lines" if lines.empty?
      rl = lines.last.split(' ')
      ver = rl[1][1..-1].chop
      case rl.size
      when 2
        cxver = 1
      when 4
        ver.chop!
        cxver = rl[3]
      else
        raise "bad release line in #{filename}: #{rl}"
      end
      Release.new(ver, cxver.to_i)
    end

  private

    def origin_dir
      Global::BASE_DIR + '.git'
    end

    def net_origin_dir
      Global::BASE_DIR + '.net'
    end

    def ssl_key
      Rugged::Credentials::SshKey.new(username:   'git',
                                      publickey:  File.expand_path("~/.ssh/id_rsa.pub"),
                                      privatekey: File.expand_path("~/.ssh/id_rsa"))
    end

    def repository_add_initial_files(dir, repo)
      host_dir = "formula/#{Global::NS_DIR[:host]}"
      target_dir = "formula/#{Global::NS_DIR[:target]}"
      orig_host_dir = Pathname.new("../formula/#{Global::NS_DIR[:host]}").realpath.to_s
      data_dir = Pathname.new(Crew::Test::DATA_DIR).realpath.to_s
      FileUtils.cd(dir) do
        FileUtils.cp "#{data_dir}/crew.old", 'crew'
        repo.add 'crew'
        FileUtils.mkdir_p ['etc', 'patches', host_dir, target_dir]
        # copy crew tools formulas
        Crew::Test::ALL_TOOLS.each { |t| FileUtils.cp "#{data_dir}/#{t.filename}-1.rb", "#{host_dir}/#{t.filename}.rb" }
        ['etc/.placeholder', "#{target_dir}/.placeholder", 'patches/.placeholder'].each do |file|
          FileUtils.touch file
          repo.add file
        end
        Dir[File.join(host_dir, '*')].each { |file| repo.add file }
        repo.commit 'add initial files'
      end
    end
  end
end
