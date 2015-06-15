require 'dentaku'
require 'csv'

class Project
  def self.available_projects
    Dir['db/*.csv'].map do |filename|
      filename.scan(%r{db\/(.*)\.csv})
    end
  end

  def initialize(name, **options)
    @name     = name
    @options  = options
    @template = CSV.new(IO.read("db/#{ name }.csv"), headers: :true).to_a.map(&:to_hash)
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
      'cylinder' => '3.1416 * radius^2 * height',
      'diameter' => 'radius * 2',
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
    template_variables.each_with_object([]) do |var, vars|
      vars.concat Dentaku::Expression.new(global_rules.fetch(var, var)).identifiers
    end.uniq.sort
  end

  def materials
    base_variables = @options.merge(global_rules.select { |k, v| template_variables.include?(k) })

    variables = @template.each_with_object(base_variables) do |material, vars|
      vars[material['name']] = material['formula']
    end

    values = Dentaku::Calculator.new.solve!(variables)

    @template.each_with_object([]) do |item, list|
      list << item.merge('quantity' => values[item['name']])
    end
  end
end
