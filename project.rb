require 'dentaku'
require 'csv'
require 'json'

class Project
  def self.available_projects
    metadata.keys
  end

  def self.metadata
    JSON.parse(File.read("db/metadata.json"))
  end

  def initialize(name, options={})
    @name       = name
    @variables  = self.class.metadata[name]["params"]
    @options    = Hash[options.map { |k,v| [k,Dentaku(v)] }]
    @template   = csv_data("db/projects/#{ name }.csv")
  end

  attr_reader :variables

  def common_formulas
    formulas = csv_data("db/common_formulas.csv")
                 .map { |e| [e['formula_name'], e['definition']] }

    Hash[formulas]
  end

  def materials
    calculator = Dentaku::Calculator.new
  
    common_formulas.each { |k,v| calculator.store_formula(k,v) }
    
    @template.map do |material|
      amt = calculator.evaluate(material['formula'], @options)

      material.merge('quantity' => amt)
    end
  end

  def shipping_weight
    calculator = Dentaku::Calculator.new

    # Build up a hash of weight formulas, keyed by material name
    weight_formulas = Hash[ 
      csv_data('db/materials.csv').map { |e| [e['name'], e['weight']] } 
    ]

    # Sum up weights for all materials in project based on quantity
    materials.reduce(0.0) { |s, e| 
      s + calculator.evaluate(weight_formulas[e['name']], e)
    }.ceil
  end

  private

  def csv_data(path)
    CSV.read(path, :headers => :true).map(&:to_hash)
  end
end
