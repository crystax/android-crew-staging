require_relative '../command_options.rb'


class UpgradeOptions

  extend CommandOptions

  def initialize(opts)
    @check_shasum = true
    @dry_run = false

    opts.each do |opt|
      case opt
      when '--no-check-shasum'
        @check_shasum = false
      when '-n', '--dry-run'
        @dry_run = true
      else
        raise "unknow option: #{opt}"
      end
    end
  end

  def check_shasum?
    @check_shasum
  end

  def dry_run?
    @dry_run
  end
end
