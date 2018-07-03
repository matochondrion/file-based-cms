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

  def app
    Sinatra::Application
  end

  def test_index
    create_document 'about.md'
    create_document 'changes.txt'

    get '/'

    assert_equal(200, last_response.status)
    assert_equal('text/html;charset=utf-8', last_response['Content-Type'])
    assert_includes(last_response.body, "about.md")
    assert_includes(last_response.body, 'changes.txt')
  end

  def test_viewing_text_document
    create_document 'about.txt', 'make all the worlds muffins'

    get '/about.txt'

    assert_equal(200, last_response.status)
    assert_equal('text/plain;charset=utf-8', last_response['Content-Type'])
    assert_includes last_response.body, 'make all the worlds muffins'
  end

  def test_viewing_markdown_document
    create_document 'about.md', '# Ruby is...'
    get '/about.md'

    assert_equal(200, last_response.status)
    assert_equal('text/html;charset=utf-8', last_response['Content-Type'])
    assert_includes(last_response.body, '<h1>Ruby is...</h1>')
  end

  def test_document_not_found
    get '/notafile.ext'

    assert_equal(302, last_response.status)

    get last_response["Location"]

    assert_equal(200, last_response.status)
    assert_includes(last_response.body, 'notafile.ext does not exist.')
  end

  def test_editing_content
    create_document 'about.txt'

    get '/about.txt/edit'

    assert_equal('text/html;charset=utf-8', last_response['Content-Type'])
    assert_includes(last_response.body, '</textarea>')
    assert_includes(last_response.body, %q(<button type="submit"))
  end

  def test_updating_content
    create_document 'changes.txt'

    post '/changes.txt', content: "new content"

    assert_equal(302, last_response.status)

    get last_response['Location']

    assert_includes(last_response.body, 'changes.txt has been updated')

    get '/changes.txt'
    assert_equal(200, last_response.status)
    assert_includes(last_response.body, "new content")
  end

  def test_view_new_document_form
    get '/new'

    assert_equal(200, last_response.status)
    assert_includes(last_response.body, '<input')
    assert_includes(last_response.body, 'Add a new document')
  end

  def test_create_new_document
    post '/create', filename: 'test.txt'
    assert_equal(302, last_response.status)

    get last_response['Location']
    assert_includes(last_response.body, 'test.txt has been created.')

    get '/'
    assert_includes(last_response.body, 'test.txt')
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

    get last_response['Location']
    assert_includes(last_response.body, 'test.txt has been deleted')

    get '/'
    refute_includes(last_response.body, 'test.txt')
  end

  def test_index_not_signed_in
    get '/'

  end

  def test_index_signed_in

  end

  def tes_

  end

  def tes_

  end

  def tes_

  end
end
