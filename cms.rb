require 'bundler/setup'
require 'sinatra'
require 'sinatra/reloader' if development?
require 'tilt/erubis'
require 'redcarpet'

configure do
  enable :sessions
  set :session_secret, 'super secret'
end

before do
  @users = [{ username: 'admin', password: 'secret' }]
end

def data_path
  if ENV['RACK_ENV'] == 'test'
    File.expand_path('../test/data', __FILE__)
  else
    File.expand_path('../data', __FILE__)
  end
end

root = File.expand_path('..', __FILE__)

def render_markdown(text)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown.render(text)
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

get '/sign-in' do
  erb :sign_in, layout: false
end

post '/sign-in' do
  session[:username] = params[:username]

  session[:signed_in] = @users.any? do |user|
    user[:username] == params[:username] &&
      user[:password] == params[:password]
  end

  if session[:signed_in]
    session[:message] = "Welcome!"
    redirect '/'
  else
    session[:message] = "Invalid Credentials"
    erb :sign_in, layout: false
  end
end

get '/sign-out' do
  session[:username] = nil
  session[:signed_in] = false
  redirect '/'
end

get '/new' do
  erb :new
end

post '/create' do
  valid_extentions = %w(.txt .md .css .html .js)
  filename = params[:filename]

  if valid_extentions.include?(File.extname(filename))
    file_path = File.join(data_path, filename)

    File.write(file_path, '')
    session[:message] = "#{filename} has been created."

    redirect '/'
  else filename.size == 0
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
  file_path = File.join(data_path, params[:filename])

  @filename = params[:filename]
  @content = File.read(file_path)

  erb :edit
end

post '/:filename' do
  file_path = File.join(data_path, params[:filename])

  File.write(file_path, params[:content])

  session[:message] = "#{params[:filename]} has been updated."
  redirect '/'
end

post '/:filename/delete' do
  file_path = File.join(data_path, params[:filename])

  File.delete(file_path)

  session[:message] = "#{params[:filename]} has been deleted."
  redirect '/'
end
