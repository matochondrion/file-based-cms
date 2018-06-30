require 'bundler/setup'
require 'sinatra'
require 'sinatra/reloader' if development?
require 'tilt/erubis'

root = File.expand_path('..', __FILE__)

before do
  @files= Dir.glob(root + '/data/*').map do |path|
    File.basename(path)
  end
end

get '/' do
  erb :index
end

get '/:filename' do
  file_path = root + '/data/' + params[:filename]

  headers['Content-Type'] = 'text/plain;charset=utf-8'
  File.read(file_path)
end
