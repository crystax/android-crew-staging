# The Formulary is a hash of formulas instances with formula fully qualified name (fqn) used as a key

require_relative 'exceptions.rb'
require_relative 'global.rb'
require_relative 'formula.rb'
require_relative 'base_package.rb'
require_relative 'package.rb'
require_relative 'utility.rb'
require_relative 'build_dependency.rb'
require_relative 'toolchain.rb'
require_relative 'arch.rb'

class Formulary

  def initialize
    @formulary = {}
    Global::NS_DIR.each_value do |dir|
      Dir[File.join(Global::FORMULA_DIR, dir, '*.rb')].sort.each do |path|
        formula = Formulary.factory(path)
        if f = @formulary[formula.fqn]
          raise "bad name '#{formula.name}' in #{formula.path}: already defined in #{f.path}"
        end
        @formulary[formula.fqn] = formula
      end
    end
  end

  def packages
    @formulary.select { |_, value| value.namespace == :target }.values
  end

  def tools
    @formulary.select { |_, value| value.namespace == :host }.values
  end

  def [](name)
    found = find(name)
    raise FormulaUnavailableError.new(name) if found.size == 0
    raise "please, specify namespace for #{name}; more than one formula exists: #{found.map(&:fqn).join(',')}" if found.size > 1
    found[0]
  end

  def find(name)
    if name.include? '/'
      [@formulary[name]].compact
    else
      @formulary.select { |_, f| f.name == name }.values
    end
  end

  def select(names)
    formulas = []
    if names.size == 0
      formulas = @formulary.values
    else
      names.each { |n| formulas << self[n] }
    end
    formulas
  end

  def dependants_of(fqn)
    list = []
    @formulary.values.each do |f|
      f.dependencies.each do |d|
        if d.fqn == fqn
          list << f
          break
        end
      end
    end
    list
  end

  def dependencies(formula)
    result = []
    deps = formula.dependencies.dup

    while deps.size > 0
      fqn = deps.shift.fqn
      f = @formulary[fqn]
      if not result.include? f
        result << f
      end
      deps += f.dependencies
    end

    result
  end

  def each(&block)
    @formulary.each_value(&block)
  end

  def self.factory(path)
    Formulary.klass(path).new(path)
  end

  def self.klass(path)
    name = File.basename(path, '.rb')
    raise FormulaUnavailableError.new(name) unless File.file? path

    mod = Module.new
    mod.module_eval(File.read(path), path)
    class_name = class_s(name)

    begin
      mod.const_get(class_name)
    rescue NameError => e
      raise FormulaUnavailableError, name, e.backtrace
    end
  end

  def self.class_s(name)
    class_name = name.capitalize
    class_name.gsub!(/[-_.\s]([a-zA-Z0-9])/) { $1.upcase }
    class_name.gsub!('+', 'x')
    class_name
  end
end
