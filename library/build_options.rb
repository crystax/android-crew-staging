class Build_options

  attr_accessor :abis
  attr_writer :build_only, :no_clean

  def initialize(opts)
    @abis = nil
    @build_only = false
    @no_clean = false

    opts.each do |opt|
      case opt
      when /^--abis=/
        @abis = opt.split('=')[1].split(',')
      when '--build-only'
        @build_only = true
      when '--no-clean'
        @no_clean = true
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
end
