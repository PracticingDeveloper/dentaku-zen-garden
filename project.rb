require 'dentaku'
require 'csv'

class Project
  def self.available_projects
    Dir['db/projects/*.csv'].map do |filename|
      filename.scan(%r{db\/projects\/(.*)\.csv})
    end.flatten
  end

  def initialize(name, **options)
    @name     = name
    @options  = options
    @template = CSV.new(IO.read("db/projects/#{ name }.csv"), headers: :true).to_a.map(&:to_hash)
  end

  def select_options(options)
    @options = options
  end

  def calculator
    @calculator ||= Dentaku::Calculator.new
  end

  def global_rules
    {
      'volume'   => 'length * width * height',
      'cylinder' => 'pi * radius^2 * height',
      'radius'   => 'diameter / 2.0',
      'pi'       => '3.1416'
    }
  end

  def template_variables
    # extract all variables from project material formulas
    @template.each_with_object([]) do |material, vars|
      vars.concat Dentaku::Expression.new(material['formula']).identifiers
    end.uniq
  end

  def variables
    # perform any global rule variable replacements
    template_variables.flat_map { |v| replace_with_dependencies(v) }.uniq.sort
  end

  def replace_with_dependencies(variable, include_transitive: false)
    # if this is a derived variable, replace it with its dependencies
    # e.g. cylinder would be replaced by radius and height
    # radius would further be replaced by diameter
    dependencies = Dentaku::Expression.new(global_rules.fetch(variable, variable)).identifiers
    dependencies.unshift(variable) if include_transitive
    dependencies.uniq.flat_map do |d|
      if d == variable
        d
      else
        replace_with_dependencies(d, include_transitive: include_transitive)
      end
    end
  end

  def materials
    variables = @template.each_with_object(@options) do |material, vars|
      vars[material['name']] = material['formula']
    end

    dependencies = variables.values.flat_map do |v|
      replace_with_dependencies(v, include_transitive: true)
    end.uniq

    rules = global_rules.select { |r, _| dependencies.include? r }

    values = Dentaku::Calculator.new.solve!(variables.merge(rules))

    @template.each_with_object([]) do |item, list|
      list << item.merge('quantity' => values[item['name']])
    end
  end

  def shipping_weight
    weight_formulas = csv_data('db/materials.csv').each_with_object({}) do |m, h|
      h[m['name']] = m['weight']
    end

    materials.inject(0.0) do |w, m|
      w + calculator.evaluate(weight_formulas[m['name']], m)
    end.ceil
  end

  private

  def csv_data(path)
    CSV.new(IO.read(path), headers: :true).to_a.map(&:to_hash)
  end
end
