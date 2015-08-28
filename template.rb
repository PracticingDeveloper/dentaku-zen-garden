class Template
  def initialize(data)
    @data         = data
    @calculator   = Dentaku::Calculator.new
  end

  def all_rules
    rules = {}

    @data.each do |material|
      rules[material['name']] = material['formula']
    end

    rules
  end
end
