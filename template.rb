class Template
  def initialize(data, global_rules)
    @data         = data
    @global_rules = global_rules
  end

  def all_rules(options)
    rules = {}

    @data.each do |material|
      rules[material['name']] = material['formula']
    end

    rules.update(options) # add in user-provided variables

    global_rule_deps = @global_rules.select { |r, _| dependencies(rules).include? r }

    rules.update(global_rule_deps) # add in globally defined variables
  end

  def all_variables
    # extract all variables from project material formulas
    @data.each_with_object([]) do |material, vars|
      vars.concat Dentaku::Expression.new(material['formula']).identifiers
    end.uniq
  end

  def unbound_variables
    # perform any global rule variable replacements
    all_variables.flat_map { |v| replace_with_dependencies(v) }.uniq.sort
  end

  private

  def dependencies(rules)
    rules.values.flat_map do |v|
      replace_with_dependencies(v, include_transitive: true)
    end.uniq
  end

  def replace_with_dependencies(variable, include_transitive: false)
    # if this is a derived variable, replace it with its dependencies
    # e.g. cylinder would be replaced by radius and height
    # radius would further be replaced by diameter
    dependencies = Dentaku::Expression.new(@global_rules.fetch(variable, variable)).identifiers
    dependencies.unshift(variable) if include_transitive
    dependencies.uniq.flat_map do |d|
      if d == variable
        d
      else
        replace_with_dependencies(d, include_transitive: include_transitive)
      end
    end
  end
end