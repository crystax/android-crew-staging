require 'rugged'
require_relative '../exceptions.rb'
require_relative '../global.rb'



module Crew

  def self.update(args)
    if args.length > 0
      raise CommandRequresNoArguments
    end

    updater = Updater.new
    updater.pull!

    report = Report.new
    report.update(updater.report)

    if report.empty?
      puts "Already up-to-date."
    else
      puts "Updated Crew from #{updater.initial_revision[0,8]} to #{updater.current_revision[0,8]}."
      report.dump
    end
  end

  private

  class Updater
    attr_reader :initial_revision, :current_revision, :repository, :repository_path

    def initialize
      @repository = Rugged::Repository.new('.')
      @repository_path = Global::BASE_DIR
    end

    def pull!
      repository.checkout 'master'
      @initial_revision = read_current_revision

      begin
        repository.fetch 'origin', credentials: make_creds
        repository.checkout 'refs/remotes/origin/master'
      rescue
        repository.reset initial_revision, :hard
        raise
      end

      @current_revision = read_current_revision
    end

    def report
      map = { tools: Hash.new { |h,k| h[k] = [] }, packages: Hash.new { |h,k| h[k] = [] } }
      formula_dir  = Global::FORMULA_DIR.basename.to_s
      packages_dir = File.join(formula_dir, Global::NS_DIR[:target])
      tools_dir    = File.join(formula_dir, Global::NS_DIR[:target])

      if initial_revision and initial_revision != current_revision
        diff.each_delta do |delta|
          src = delta.old_file[:path]
          dst = delta.new_file[:path]

          next unless File.extname(dst) == ".rb"
          next unless [src, dst].any? { |p| File.dirname(p).start_with?(formula_dir) }

          status = delta.status_char.to_s
          type = File.basename(File.dirname(src)).to_sym
          case status
          when "A", "M", "D"
            map[type][status.to_sym] << repository_path.join(src)
          when "R"
            map[type][:D] << repository_path.join(src)
            map[type][:A] << repository_path.join(dst)
          end
        end
      end

      map
    end

    private

    def read_current_revision
      # git rev-parse -q --verify HEAD"
      repository.rev_parse_oid('HEAD')
    end

    def diff
      # git diff-tree -r --name-status --diff-filter=AMDR -M85% initial_revision current_revision
      init = repository.lookup(initial_revision)
      curr = repository.lookup(current_revision)
      init.diff(curr).find_similar!({ :rename_threshold => 85, :renames => true })
    end

    def make_creds
      Utils.make_git_credentials repository.remotes['origin'].url
    end
  end

  class Report
    def initialize
      @hash = { tools: {}, packages: {} }
    end

    def update(h)
      @hash[:tools].update(h[:tools])
      @hash[:packages].update(h[:packages])
    end

    def empty?
      @hash[:tools].empty? and @hash[:packages].empty?
    end

    def dump
      # Key Legend: Added (A), Copied (C), Deleted (D), Modified (M), Renamed (R)
      dump_formula_report(:tools, :M, "Updated Utilities")
      dump_formula_report(:tools, :A, "New Utilities")
      dump_formula_report(:tools, :D, "Deleted Utilities")
      dump_formula_report(:packages, :A, "New Formulae")
      dump_formula_report(:packages, :M, "Updated Formulae")
      dump_formula_report(:packages, :D, "Deleted Formulae")
    end

    private

    def dump_formula_report(type, key, title)
      formula = select_formula(type, key)
      unless formula.empty?
        puts "==> #{title}"
        puts formula
      end
    end

    def select_formula(type, key)
      fetch(type, key, []).map do |path|
          path.basename(".rb").to_s
      end.sort.join(', ')
    end

    def fetch(type, *args)
      @hash[type].fetch(*args)
    end
  end
end
