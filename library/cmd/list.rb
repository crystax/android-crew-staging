require_relative '../exceptions.rb'
require_relative '../release.rb'
require_relative '../formulary.rb'


class Element

  attr_reader :name, :version, :crystax_version, :installed_sign, :installed_source

  def initialize(name, version, cversion, iflag, sflag)
    @name = name
    @version = version
    @crystax_version = cversion
    @installed_sign = iflag ? '*' : ' '
    @installed_source = sflag ? '  source' : ''
  end

  def <=>(e)
    "#{name} #{version}" <=> "#{e.name} #{e.version}"
  end
end


module Crew

  def self.list(args)
    formulary = Formulary.new

    case args.length
    when 0
      puts "Tools:"
      list_elements formulary.tools
      puts "Packages:"
      list_elements formulary.packages
    when 1
      case args[0]
      when '--packages'
        list_elements formulary.packages
      when '--tools'
        list_elements formulary.tools
      when /^--require-rebuild=/
        raise "--require-rebuild requires at least one formula name specified"
      else
        raise "bad command syntax; try ./crew help list"
      end
    else
      raise "bad command syntax; try ./crew help list" unless args[0] =~ /^--require-rebuild=/
      check_type = args[0].split('=')[1]
      raise "--require-rebuild argument can be 'last' or 'all'" unless ['last', 'all'].include? check_type
      args.shift
      list_require_rebuild check_type, args, formulary
    end
  end

  # private

  def self.list_elements(hash)
    list = []
    max_name_len = max_ver_len = max_cxver_len = 0
    hash.each_value do |f|
      f.releases.each do |r|
        max_name_len = f.name.size if f.name.size > max_name_len
        ver = r.version
        max_ver_len = ver.size if ver.size > max_ver_len
        if not r.installed?
          cxver = r.crystax_version.to_s
        else
          cxver = r.installed_crystax_version.to_s
          if r.installed_crystax_version != r.crystax_version
            cxver += " (#{r.crystax_version})"
          end
        end
        max_cxver_len = cxver.to_s.size if cxver.to_s.size > max_cxver_len
        list << Element.new(f.name, ver, cxver, r.installed?, r.source_installed?)
      end
    end

    list.sort.each do |l|
      printf " %s %-#{max_name_len}s  %-#{max_ver_len}s  %-#{max_cxver_len}s%s\n", l.installed_sign, l.name, l.version, l.crystax_version, l.installed_source
    end
  end

  def self.list_require_rebuild(check_type, args, formulary)
    names = []
    args.each do |n|
      formula = formulary[n]
      fct = File.ctime(formula.path)
      releases = (check_type == 'last') ? [formula.releases.last] : formula.releases
      platforms = (Global::OS == 'darwin') ? ['darwin-x86_64'] : ['linux-x86_64', 'windows-x86_64', 'windows']
      releases.each do |release|
        platforms.map { |p| File.join(Global::PKG_CACHE_DIR, formula.archive_filename(release, p)) }.uniq.each do |file|
          names << n if not File.exist?(file) or (File.ctime(file) < fct)
        end
      end
    end
    puts names.uniq.join(' ')
  end
end
