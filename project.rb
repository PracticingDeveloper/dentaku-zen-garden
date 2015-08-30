require 'csv'
require 'json'

class << (Project = Object.new)
  def available_projects
    metadata.keys
  end

  def variables(project)
    metadata[project]["params"]
  end

  def common_formulas
    csv_hash("db/common_formulas.csv", "formula_name", "definition")
  end

  def weight_formulas
    csv_hash('db/materials.csv', 'name', 'weight')
  end

  def quantity_formulas(name)
    csv_table("db/projects/#{ name }.csv")
  end

  private

  def metadata
    JSON.parse(File.read("db/metadata.json"))
  end

  def csv_table(path)
    CSV.read(path, :headers => :true).map(&:to_hash)
  end

  def csv_hash(path, key, value)
    Hash[csv_table(path).map { |e| [e[key], e[value]] }]
  end
end
