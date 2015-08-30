require 'dentaku'

require_relative "project"

class Calculator
  def initialize(project_name, params={})
    @params = Hash[params.map { |k,v| [k,Dentaku(v)] }]

    @quantity_formulas = Project.quantity_formulas(project_name)
    @common_formulas   = Project.common_formulas
    @weight_formulas   = Project.weight_formulas
  end

  def materials
    calculator = Dentaku::Calculator.new

    @common_formulas.each { |k,v| calculator.store_formula(k,v) }
    
    @quantity_formulas.map do |material|
      amt = calculator.evaluate(material['formula'], @params)

      material.merge('quantity' => amt)
    end
  end

  def shipping_weight
    calculator = Dentaku::Calculator.new

    # Sum up weights for all materials in project based on quantity
    materials.reduce(0.0) { |s, e| 
      s + calculator.evaluate(@weight_formulas[e['name']], e)
    }.ceil
  end
end