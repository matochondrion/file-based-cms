require 'bundler/setup'
require 'sinatra'
require 'sinatra/reloader' if development?
require 'tilt/erubis'

root = File.expand_path('..', __FILE__)

get '/' do
  @root = root
  @files= Dir.glob(root + '/data/*').map do |path|
    File.basename(path)
  end
  erb :index
end

