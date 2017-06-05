require_relative 'command_options.rb'


class CleanupOptions

  extend CommandOptions

  def initialize(opts)
    @dry_run = false

    if opts.empty? or (opts.size == 1 and (opts[0] == '-n' or opts[0] == '--dry-run'))
      @clean_pkg_cache = true
      @clean_src_cache = true
    else
      @clean_pkg_cache = false
      @clean_pkg_cache = false
    end

    opts.each do |opt|
      case opt
      when '-n', '--dry-run'
        @dry_run = true
      when '--pkg-cache'
        @clean_pkg_cache = true
      when '--src-cache'
        @clean_src_cache = true
      else
        raise "unknow option: #{opt}"
      end
    end
  end

  def dry_run?
    @dry_run
  end

  def clean_pkg_cache?
    @clean_pkg_cache
  end

  def clean_src_cache?
    @clean_src_cache
  end
end
