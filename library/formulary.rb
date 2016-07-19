# The Formulary is a hash of formulas instances with formula name used as a key

require_relative 'exceptions.rb'
require_relative 'global.rb'
require_relative 'formula.rb'
require_relative 'part.rb'
require_relative 'package.rb'
require_relative 'utility.rb'
require_relative 'build_dependency.rb'

class Formulary

  def self.parts
    Formulary.new(Global::PARTS_DIR)
  end

  def self.packages
    Formulary.new(Global::FORMULA_DIR)
  end

  def self.utilities
    Formulary.new(Global::UTILITIES_DIR)
  end

  def self.build_dependencies
    Formulary.new(Global::BUILD_DEPENDENCIES_DIR)
  end

  def self.all_formulas
    { part: parts, package: packages, utility: utilities, build_dependency: build_dependencies }
  end

  def initialize(dir)
    @formulary = {}
    Dir[File.join(dir, '*.rb')].sort.each do |path|
      formula = Formulary.factory(path)
      if f = @formulary[formula.name]
        raise "#{formula.name} has bad user name #{formula.user_name}: the same user name already defined in #{f.path}"
      end
      @formulary[formula.name] = formula
    end
  end

  def each(&block)
    @formulary.each_value(&block)
  end

  def [](name)
    formula = @formulary[name]
    raise FormulaUnavailableError.new(name) unless formula
    formula
  end

  def member?(name)
    @formulary.member? name
  end

  def select(&block)
    @formulary.select(&block)
  end

  def dependants_of(name)
    list = []
    @formulary.values.each do |f|
      f.dependencies.each do |d|
        if d.name == name
          list << f
          break
        end
      end
    end
    list
  end

  # private

  def self.factory(path)
    Formulary.klass(path).new(path)
  end

  def self.klass(path)
    name = path_to_formula_name(path)
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

  def self.path_to_formula_name(path)
    File.basename(path, '.rb')
  end
end
