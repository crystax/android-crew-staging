require_relative '../arch.rb'
require_relative '../command_options.rb'


class MakePosixEnvOptions

  extend CommandOptions

  attr_accessor :top_dir, :abi

  def initialize(opts)
    @make_tarball = true
    @check_shasum = true

    opts.each do |opt|
      case opt
      when /^--top-dir=/
        @top_dir = opt.split('=')[1]
      when /^--abi=/
        @abi = opt.split('=')[1]
        raise "unknown abi '#{@abi}'" unless Arch::ABI_LIST.include? @abi
      when '--no-tarball'
        @make_tarball = false
      when '--no-check-shasum'
        @check_shasum = false
      else
        raise "unknow option: #{opt}"
      end
    end

    raise "--top-dir option is requried" unless @top_dir
    raise "--abi option is requried"     unless @abi
  end

  def make_tarball?
    @make_tarball
  end

  def check_shasum?
    @check_shasum
  end
end
