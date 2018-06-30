require 'bundler/setup'
require 'sinatra'
require 'sinatra/reloader' if development?
require 'tilt/erubis'

configure do
  enable :sessions
  set :session_secret, 'super secret'
end

root = File.expand_path('..', __FILE__)

before do
  @message = nil
  @files= Dir.glob(root + '/data/*').map do |path|
    File.basename(path)
  end
end

get '/' do
  erb :index
end

get '/:filename' do
  file_path = root + '/data/' + params[:filename]

  if File.file?(file_path)
    headers['Content-Type'] = 'text/plain;charset=utf-8'
    File.read(file_path)
  else
    session[:message] = "#{params[:filename]} does not exist."
    redirect '/'
  end
end

