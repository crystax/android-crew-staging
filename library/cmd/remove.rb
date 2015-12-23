require_relative '../exceptions.rb'
require_relative '../release.rb'
require_relative '../formulary.rb'


module Crew

  def self.remove(args)
    if args.count < 1
      raise FormulaUnspecifiedError
    end

    formulary = Formulary.libraries

    args.each do |n|
      name, version = n.split(':')
      outname = name + (version ? ':' + version : "")

      formula = formulary[name]

      release = Release.new(version)
      raise "#{outname} is not installed" if !formula.installed?(release)

      survive_rm = formula.releases.select { |r| r.installed? and !r.match(release) }
      ideps = formulary.dependants_of(name).select { |d| d.installed? }
      if ideps.count > 0 and survice_rm.count == 0
        raise "#{outname} has installed dependants: #{ideps.map{|f| f.name}.join(', ')}"
      end

      formula.releases.each { |r| formula.uninstall(r) if r.installed? and r.match?(release) }

      # todo: update root android.mk
      # if options[:rm_binary]
      #   formula.actualize_root_android_mk
      # end

      # todo: clean empty dirs
    end
  rescue FormulaUnavailableError => exc
    if not Formulary.utilities.member? exc.name
      raise
    else
      raise "could not remove utility #{exc.name}"
    end
  end
end
