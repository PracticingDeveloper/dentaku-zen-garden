require 'dentaku'
require 'csv'

require_relative "template"

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

  def variables
    Template.new(@template, global_rules).unbound_variables
  end

  def materials
    t = Template.new(@template, global_rules)

    values = Dentaku::Calculator.new.solve!(t.all_rules(@options))

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
