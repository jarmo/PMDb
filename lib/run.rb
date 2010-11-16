require "sinatra"
require "haml"
#raise "wrong ruby version" unless RUBY_VERSION == "1.9.1"

class MyClass
end

configure do
  def b
    @@b ||= MyClass.new
  end
end

get "/" do
  haml :index
end

get '/css/pmdb.css' do
  content_type 'text/css', :charset => 'utf-8'
  scss :pmdb
end