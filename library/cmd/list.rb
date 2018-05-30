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
      list_elements sort_by_name(formulary.tools)
      puts "Packages:"
      list_elements sort_by_name(formulary.packages)
    when 1
      case args[0]
      when '--packages'
        list_elements sort_in_buildable_order(formulary, formulary.packages)
      when '--tools'
        list_elements sort_by_name(formulary.tools)
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

  def self.sort_by_name(formulas)
    formulas.sort { |f1, f2| f1.name <=> f2.name }
  end

  def self.sort_in_buildable_order(formulary, formulas)
    Struct.new('Pair', :formula, :dependencies)
    unresolved = sort_by_name(formulas).map { |f| Struct::Pair.new(f, formulary.dependencies(f).map(&:fqn)) }
    resolved, unresolved = sort_in_buildable_order_impl([], unresolved)

    unless unresolved.empty?
      ustr = unresolved.reduce('') { |acc, uf| acc += "#{uf.formula.fqn}: #{uf.dependencies}\n" }
      raise "unresolved dependencies: #{ustr}"
    end

    resolved
  end

  def self.sort_in_buildable_order_impl(resolved, unresolved)
    rf = unresolved.find { |e| e.dependencies.empty? }
    if not rf
      [resolved, unresolved]
    else
      unresolved.delete rf
      resolved << rf.formula
      unresolved = unresolved.map { |uf| Struct::Pair.new(uf.formula, uf.dependencies.delete_if { |e| rf.formula.fqn == e }) }
      sort_in_buildable_order_impl resolved, unresolved
    end
  end

  def self.list_elements(elements)
    list = []
    max_name_len = max_ver_len = max_cxver_len = 0
    elements.each do |f|
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

    list.each do |l|
      printf " %s %-#{max_name_len}s  %-#{max_ver_len}s  %-#{max_cxver_len}s%s\n", l.installed_sign, l.name, l.version, l.crystax_version, l.installed_source
    end
  end
end
