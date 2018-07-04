require 'bundler/setup'
require 'sinatra'
require 'sinatra/reloader' if development?
require 'tilt/erubis'
require 'redcarpet'
require 'yaml'

configure do
  enable :sessions
  set :session_secret, 'super secret'
end

def data_path
  if ENV['RACK_ENV'] == 'test'
    File.expand_path('../test/data', __FILE__)
  else
    File.expand_path('../data', __FILE__)
  end
end

def render_markdown(text)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown.render(text)
end

def load_user_credentials
  credentials_path = if ENV['RACK_ENV'] == 'test'
    File.expand_path('../test/users.yml', __FILE__)
  else
    File.expand_path('../users.yml', __FILE__)
  end

  YAML.load_file(credentials_path)
end

def valid_user?(username, password)
  load_user_credentials.any? do |valid_username, valid_password|
    puts valid_username
    puts valid_password
    username == valid_username && password == valid_password
  end
end

def user_signed_in?
  return true if session[:username]
  false
end

def require_signed_in_user
  unless user_signed_in?
    session[:message] = 'You must be signed in to do that.'
    redirect '/'
  end
end

def load_file_content(path)
  case File.extname(path)
  when '.txt'
    headers['Content-Type'] = 'text/plain;charset=utf-8'
    File.read(path)
  when '.md'
    erb render_markdown(File.read(path))
  end
end

get '/' do
  pattern = File.join(data_path, '*')
  @files = Dir.glob(pattern).map do |path|
    File.basename(path)
  end
  erb :index
end

get '/users/signin' do
  erb :sign_in, layout: false
end

post '/users/signin' do
  if valid_user?(params[:username], params[:password])
    session[:username] = params[:username]
    session[:message] = "Welcome!"
    redirect '/'
  else
    session[:message] = "Invalid Credentials"
    status 422
    erb :sign_in, layout: false
  end
end

post '/users/signout' do
  session.delete(:username)
  session[:message] = 'You have been signed out.'
  redirect '/'
end

get '/new' do
  require_signed_in_user

  erb :new
end

post '/create' do
  require_signed_in_user

  valid_extentions = %w(.txt .md .css .html .js)
  filename = params[:filename]

  if valid_extentions.include?(File.extname(filename))
    file_path = File.join(data_path, filename)

    File.write(file_path, '')
    session[:message] = "#{filename} has been created."

    redirect '/'
  else
    session[:message] = "A name is required with a valid exention of:
    #{valid_extentions}."
    status 422
    erb :new
  end
end

get '/:filename' do
  file_path = File.join(data_path, params[:filename])

  if File.exist?(file_path)
    load_file_content(file_path)
  else
    session[:message] = "#{params[:filename]} does not exist."
    redirect '/'
  end
end

get '/:filename/edit' do
  require_signed_in_user

  file_path = File.join(data_path, params[:filename])

  @filename = params[:filename]
  @content = File.read(file_path)

  erb :edit
end

post '/:filename' do
  require_signed_in_user

  file_path = File.join(data_path, params[:filename])

  File.write(file_path, params[:content])

  session[:message] = "#{params[:filename]} has been updated."
  redirect '/'
end

post '/:filename/delete' do
  require_signed_in_user

  file_path = File.join(data_path, params[:filename])

  File.delete(file_path)

  session[:message] = "#{params[:filename]} has been deleted."
  redirect '/'
end

=begin
* create a users.yml file
* write a method to check if a pair of username and password are valid in the
.yml fihle
  - load a file with File.read
  - pass it to YAML.load() and assign a new variable
  - iterate over the hashe with key value pairs and check of there are any matches

* if a name matches then sign user in
* format of yaml file:
  ----

  ...
=end
