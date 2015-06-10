require 'dentaku'
require 'csv'

class Project
  def initialize(name, **options)
    @name     = name
    @options  = options
    @template = CSV.new(IO.read("db/#{ name }.csv"), headers: :true).to_a.map(&:to_hash)
  end

  def materials
    base_variables = @options.merge(
      'volume' => 'length * width * height'
    )

    variables = @template.each_with_object(base_variables) do |material, vars|
      vars[material['name']] = material['formula']
    end

    values = Dentaku::Calculator.new.solve!(variables)

    @template.each_with_object([]) do |item, list|
      list << item.merge('quantity' => values[item['name']])
    end
  end
end

calm = Project.new("calm", length: 30, width: 20, height: 5)

puts "Materials:"
calm.materials.each do |material|
  puts "#{ material['quantity'].to_i } #{ material['unit'] } - #{ material['name'] }"
end
