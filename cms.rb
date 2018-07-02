require 'bundler/setup'
require 'sinatra'
require 'sinatra/reloader' if development?
require 'tilt/erubis'
require 'redcarpet'

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

def render_markdown(text)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown.render(text)
end

def load_file_content(file_path)
  content = File.read(file_path)
  case File.extname(file_path)
  when '.txt'
    headers['Content-Type'] = 'text/plain;charset=utf-8'
    File.read(file_path)
  when '.md'
    render_markdown(File.read(file_path))
  end
end

get '/' do
  erb :index
end

get '/:filename' do
  file_path = root + '/data/' + params[:filename]

  if File.exists?(file_path)
    load_file_content(file_path)
  else
    session[:message] = "#{params[:filename]} does not exist."
    redirect '/'
  end
end

get '/:filename/edit' do
  file_path = root + '/data/' + params[:filename]

  if File.exists?(file_path)
    @filename = params[:filename]
    @content = File.read(file_path)
  else
    session[:message] = "#{params[:filename]} does not exist."
    redirect '/'
  end

  erb :edit
end

post '/:filename' do
  file_path = root + '/data/' + params[:filename]
  File.write(file_path, params[:content])
  session[:message] = "#{params[:filename]} has been updated."
  redirect '/'
end

