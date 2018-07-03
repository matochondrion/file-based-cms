ENV['RACK_ENV'] = 'test'

require 'bundler/setup'
require 'minitest/autorun'
require 'rack/test'
require 'fileutils'

require_relative '../cms'

class CMSTest < Minitest::Test
  include Rack::Test::Methods

  def setup
    FileUtils.mkdir_p(data_path)
  end

  def teardown
    FileUtils.rm_rf(data_path)
  end

  def create_document(name, content = '')
    # File.write(File.join(data_path, name), content)

    File.open(File.join(data_path, name), 'w') do |file|
      file.write(content)
    end
  end

  def session
    last_request.env['rack.session']
  end

  def sign_in
    post '/users/signin', username: 'admin', password: 'secret'
  end

  def app
    Sinatra::Application
  end

  def test_index
    sign_in
    create_document 'about.md'
    create_document 'changes.txt'

    get '/'

    # assert_equal(200, last_response.status)
    # assert_equal('text/html;charset=utf-8', last_response['Content-Type'])
    # assert_includes(last_response.body, "about.md")
    assert_includes(last_response.body, 'changes.txt')
  end

  def test_viewing_text_document
    sign_in
    create_document 'about.txt', 'make all the worlds muffins'

    get '/about.txt'

    assert_equal(200, last_response.status)
    assert_equal('text/plain;charset=utf-8', last_response['Content-Type'])
    assert_includes last_response.body, 'make all the worlds muffins'
  end

  def test_viewing_markdown_document
    sign_in
    create_document 'about.md', '# Ruby is...'
    get '/about.md'

    assert_equal(200, last_response.status)
    assert_equal('text/html;charset=utf-8', last_response['Content-Type'])
    assert_includes(last_response.body, '<h1>Ruby is...</h1>')
  end

  def test_document_not_found
    get '/notafile.ext'

    assert_equal(302, last_response.status)
    assert_equal('notafile.ext does not exist.', session[:message])
  end

  def test_editing_content
    sign_in
    create_document 'about.txt'

    get '/about.txt/edit'

    assert_equal('text/html;charset=utf-8', last_response['Content-Type'])
    assert_includes(last_response.body, '</textarea>')
    assert_includes(last_response.body, %q(<button type="submit"))
  end

  def test_updating_content
    post '/changes.txt', content: "new content"

    assert_equal(302, last_response.status)
    assert_equal('changes.txt has been updated.', session[:message])

    get '/changes.txt'
    assert_equal(200, last_response.status)
    assert_includes(last_response.body, "new content")
  end

  def test_view_new_document_form
    sign_in
    get '/new'

    assert_equal(200, last_response.status)
    assert_includes(last_response.body, '<input')
    assert_includes(last_response.body, 'Add a new document')
  end

  def test_create_new_document
    post '/create', filename: 'test.txt'

    assert_equal(302, last_response.status)
    assert_equal('test.txt has been created.', session[:message])
  end

  def test_create_new_document_without_filename
    post '/create', filename: ''

    assert_equal(422, last_response.status)
    assert_includes(last_response.body, 'A name is required')
  end

  def test_deleting_document
    create_document('test.txt')

    post '/test.txt/delete'
    assert_equal(302, last_response.status)
    assert_equal('test.txt has been deleted.', session[:message])

    get '/'
    refute_includes(last_response.body, %q(href="/test.txt))
  end

  def test_signin_form
    get '/users/signin'

    assert_equal 200, last_response.status
    assert_includes last_response.body, '<input'
    assert_includes last_response.body, %q(<button type="submit")
  end

  def test_signin
    post '/users/signin', username: 'admin', password: 'secret'
    assert_equal 302, last_response.status
    assert_equal 'Welcome!', session[:message]
    assert_equal 'admin', session[:username]

    get last_response['Location']
    assert_includes last_response.body, 'Signed in as admin'
  end

  def test_signin_with_bad_credentials
    post '/users/signin', username: 'guest', password: 'shhhh'
    assert_equal 422, last_response.status
    assert_nil session[:username]
    assert_includes last_response.body, "Invalid Credentials"
  end

  def test_signout
    sign_in
    get '/', {}, {'rack.session' => { username: 'admin', password: 'secret'} }
    assert_equal 'secret', session[:password]
    assert_includes last_response.body, 'Signed in as admin'

    post '/users/signout'
    get last_response['Location']

    assert_nil session[:username]
    assert_includes last_response.body, 'You have been signed out'
    assert_includes last_response.body, 'Sign In'
  end

end
