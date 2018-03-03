require_relative '../arch.rb'
require_relative '../command_options.rb'


class MakeDebOptions

  extend CommandOptions

  attr_accessor :deb_root_prefix, :abis

  def initialize(opts)
    @abis = Arch::ABI_LIST
    @all_versions = false
    @clean = true
    @check_shasum = true

    opts.each do |opt|
      case opt
      when /^--deb-root-prefix=/
        @deb_root_prefix = opt.split('=')[1]
      when '--all-versions'
        @all_versions = true
      when /^--abis=/
        @abis = opt.split('=')[1].split(',')
      when '--no-clean'
        @clean = false
      when '--no-check-shasum'
        @check_shasum = false
      else
        raise "unknow option: #{opt}"
      end
    end
  end

  def all_versions?
    @all_versions
  end

  def clean?
    @clean
  end

  def check_shasum?
    @check_shasum
  end
end
