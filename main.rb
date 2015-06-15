require_relative './project'

puts 'Enter project name:'
puts "  available project templates: #{ Project.available_projects.join(', ') }"

project_name = $stdin.gets.chomp

project = Project.new(project_name)

puts
puts 'Select options:'
options = project.variables.each_with_object({}) do |var, opts|
  print "#{ var }:"
  opts[var] = $stdin.gets.chomp
end

project.select_options(options)

puts
puts 'Materials:'
project.materials.each do |material|
  puts "#{ material['quantity'].to_i } #{ material['unit'] } - #{ material['name'] }"
end
