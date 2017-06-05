require_relative 'platform.rb'

module CommandOptions

  def parse_args(args)
    # todo: use more sophisticated conditions to select options?
    opts, args = args.partition { |a| a.start_with? '-' }
    [self.new(opts), args]
  end
end
