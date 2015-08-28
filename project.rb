require 'dentaku'
require 'csv'
require 'json'

require_relative "template"

class Project
  def self.available_projects
    Dir['db/projects/*.csv'].map do |filename|
      filename.scan(%r{db\/projects\/(.*)\.csv})
    end.flatten
  end

  def initialize(name, **options)
    @name       = name
    @options    = options
    @template   = CSV.new(IO.read("db/projects/#{ name }.csv"), headers: :true).to_a.map(&:to_hash)

    @variables  = JSON.parse(IO.read("db/metadata.json"))[name]["params"]
  end

  attr_reader :variables

  def select_options(options)
    @options = options
  end

  def global_rules
    {
      'box_volume'       => 'rect_area * height',
      'rect_area'        => 'length * width',
      'rect_perimeter'   => '2 * length + 2 * width',
      'cylinder_volume'  => 'circular_area * height',
      'circumference'    => 'pi * diameter',
      'circular_area'    => 'pi * radius^2',
      'radius'           => 'diameter / 2.0',
      'pi'               => '3.1416',
      'fill'             => '0.7'
    }
  end

  def materials
    t = Template.new(@template)

    calculator = Dentaku::Calculator.new
  
    global_rules.each { |k,v| calculator.store_formula(k,v) }

    @options.each do |k,v|
      calculator.store_formula(k,v)
    end

    values = calculator.solve!(t.all_rules)

    @template.each_with_object([]) do |item, list|
      list << item.merge('quantity' => values[item['name']])
    end
  end

  def shipping_weight
    calculator = Dentaku::Calculator.new

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
