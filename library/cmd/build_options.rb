require_relative '../global.rb'
require_relative '../utils.rb'
require_relative '../arch.rb'
require_relative '../platform.rb'
require_relative '../command_options.rb'


class BuildOptions

  extend CommandOptions

  attr_accessor :platforms, :abis, :num_jobs
  attr_writer :source_only, :build_only, :no_install, :no_clean, :update_shasum, :check

  def initialize(opts)
    @abis = Arch::ABI_LIST
    @source_only = false
    @build_only = false
    @install = true
    @no_clean = false
    @check = false
    @all_versions = false
    @update_shasum = false
    @num_jobs = Utils.processor_count * 2
    @platforms = Platform.default_names_for_host_os

    @num_jobs_default = true

    opts.each do |opt|
      case opt
      when '--source-only'
        @source_only = true
        @no_clean = true
      when '--build-only'
        @build_only = true
        @no_clean = true
      when '--no-install'
        @install = false
      when '--no-clean'
        @no_clean = true
      when '--update-shasum'
        @update_shasum = true
      when /^--num-jobs=/
        @num_jobs = opt.split('=')[1].to_i
        @num_jobs_default = false
      when /^--platforms=/
        @platforms = opt.split('=')[1].split(',')
      when '--check'
        @check = true
      when '--all-versions'
        @all_versions = true
      when /^--abis=/
        @abis = opt.split('=')[1].split(',')
      else
        raise "unknow option: #{opt}"
      end
    end
  end

  def source_only?
    @source_only
  end

  def build_only?
    @build_only
  end

  def install?
    @install
  end

  def clean?
    @no_clean == false
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

  def all_versions?
    @all_versions
  end

  def num_jobs_default?
    @num_jobs_default
  end
end
