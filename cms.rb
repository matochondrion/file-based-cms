require 'bundler/setup'
require 'sinatra'
require 'sinatra/reloader' if development?
require 'tilt/erubis'

=begin
- create a method that lists all the files in documents dir and adds them to an array
- add the array to an instance varaible @documents
- create a view that iteratres over the ara to display the file names

=end

get '/' do
  @documents_locations = Dir.glob('data/*')
  @documents = @documents_locations.map { |doc| File.basename(doc) }
  erb :home
end

