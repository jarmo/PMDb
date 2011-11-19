require "bundler"
Bundler.setup
require "sinatra/base"
require "haml"
require 'compass'

class PMDb < Sinatra::Base
  configure do
    Compass.configuration do |config|
      config.project_path = File.dirname(__FILE__)
      config.sass_dir = 'views'
    end

    set :haml, {:format => :html5}
    set :scss, Compass.sass_engine_options
    enable :logging
  end

  get "/" do
    haml :index
  end

  get '/css/pmdb.css' do
    content_type 'text/css', :charset => 'utf-8'
    scss :pmdb
  end

  run! if app_file == $0
end
