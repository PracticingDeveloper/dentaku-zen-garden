require "bundler"
Bundler.require

require 'sinatra'
require_relative 'project'
require_relative 'calculator'

get '/' do
  @available_projects = Project.available_projects
  erb :index, layout: :app
end

get '/:project' do
  erb :project, layout: :app
end

post '/:project' do
  @calculator = Calculator.new(params[:project], params[:variables])
  erb :materials, layout: :app
end
