require_relative 'global.rb'
require_relative 'utils.rb'
require_relative 'build.rb'
require_relative 'platform.rb'


class Build_options

  attr_accessor :platforms, :abis, :num_jobs
  attr_writer :build_only, :no_clean, :update_shasum, :check

  def initialize(opts)
    @abis = Build::ABI_LIST
    @build_only = false
    @no_clean = false
    @check = false
    @update_shasum = false
    @num_jobs = Utils.processor_count * 2

    @platforms = case Global::OS
                 when 'linux'  then ['linux-x86_64', 'linux-x86', 'windows-x86_64', 'windows']
                 when 'darwin' then ['darwin-x86_64', 'darwin-x86']
                 else []
                 end

    opts.each do |opt|
      case opt
      when '--build-only'
        @build_only = true
      when '--no-clean'
        @no_clean = true
      when '--update-shasum'
        @update_shasum = true
      when /^--num-jobs=/
        @num_jobs = opt.split('=')[1].to_i
      when /^--platforms=/
        @platforms = opt.split('=')[1].split(',')
      when '--check'
        @check = true
      when /^--abis=/
        @abis = opt.split('=')[1].split(',')
      else
        raise "unknow option: #{opt}"
      end
    end
  end

  def build_only?
    @build_only
  end

  def no_clean?
    @no_clean
  end

  def update_shasum?
    @update_shasum
  end

  def check?(platform)
    @check and (Global::OS == platform.target_os)
  end
end
