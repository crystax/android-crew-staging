require_relative '../exceptions.rb'
require_relative '../release.rb'
require_relative '../formulary.rb'
require_relative 'list/options.rb'


module Crew

  def self.list(args)
    List.new(args).execute
  end

  class List

    attr_reader :options, :formulary

    def initialize(args)
      @formulary = Formulary.new
      @options, rest = Options.parse_args(args)
      raise CommandRequresNoArguments if rest.size > 0
    end

    def execute
      list('Tools:',    formulary.tools, :tools)       if options.list_tools?
      list('Packages:', formulary.packages, :packages) if options.list_packages?
    end

    private

    def list(title, formulas, type)
      output(title, sort(formulas), type)
    end

    def sort(formulas)
      if options.buildable_order?
        sort_in_buildable_order(formulas)
      else
        sort_by_name(formulas)
      end
    end

    def sort_by_name(formulas)
      formulas.sort { |f1, f2| f1.name <=> f2.name }
    end

    def sort_in_buildable_order(formulas)
      Struct.new('Pair', :formula, :dependencies)
      unresolved = sort_by_name(formulas).map { |f| Struct::Pair.new(f, formulary.dependencies(f).map(&:fqn)) }
      resolved, unresolved = sort_in_buildable_order_impl([], unresolved)

      unless unresolved.empty?
        ustr = unresolved.reduce('') { |acc, uf| acc += "#{uf.formula.fqn}: #{uf.dependencies}\n" }
        raise "unresolved dependencies: #{ustr}"
      end

      resolved
    end

    def sort_in_buildable_order_impl(resolved, unresolved)
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

    FLAG_MSG = { source:                  'source',
                 no_source:               '',
                 no_dev_files:            '',
                 dev_files_installed:     'dev files',
                 dev_files_not_installed: 'no dev files'
               }

    Element = Struct.new(:name, :version, :crystax_version, :installed_sign, :flag) do
      def initialize(name, version, crystax_version, iflag, flag)
        super name, version, crystax_version, (iflag ? '*' : ' '), FLAG_MSG[flag]
      end

      def <=>(e)
        "#{name} #{version}" <=> "#{e.name} #{e.version}"
      end
    end

    def output(title, elements, type)
      puts title unless options.no_title?

      if options.names_only?
        puts elements.map(&:name).join(' ')
      else
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
            flag = case type
                   when :packages
                     r.source_installed? ? :source : :no_source
                   when :tools
                     if !f.respond_to?(:has_dev_files?)
                       :no_dev_files
                     elsif !f.has_dev_files?
                       :no_dev_files
                     elsif f.dev_files_installed?(r)
                       :dev_files_installed
                     else
                       :dev_files_not_installed
                     end
                   else
                     raise "bad type #{type}"
                   end
            list << Element.new(f.name, ver, cxver, r.installed?, flag)
          end
        end

        list.each do |l|
          printf " %s %-#{max_name_len}s  %-#{max_ver_len}s  %-#{max_cxver_len}s  %s\n", l.installed_sign, l.name, l.version, l.crystax_version, l.flag
        end
      end
    end
  end
end
