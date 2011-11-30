require 'bundler'
Bundler.setup

require 'sinatra/base'
require 'sinatra/reloader'
require 'haml'
require 'compass'
require 'yaml'
require 'pathname'
require 'parallel'
require 'net/http'
require 'yajl'
require 'imdb'

require_relative 'pathname_ext'
require_relative 'movie_finder'
require_relative 'imdb'

class PMDb < Sinatra::Base
  helpers do
    class << self
      def pmdb_config
        YAML.load(File.read(File.dirname(__FILE__) + '/../config.yml'))
      end
    end

    def movies
      MovieFinder.new(settings.pmdb).movies
    end

    def rescan_movies
      MovieFinder.new(settings.pmdb).rescan
    end

    def hide_movie dir, path
      MovieFinder.new(settings.pmdb).hide_movie dir, path
    end
  end

  configure do
    Compass.configuration do |config|
      config.project_path = File.dirname(__FILE__)
      config.sass_dir = 'views'
    end

    set :haml, {:format => :html5}
    set :scss, Compass.sass_engine_options
    set :port, pmdb_config["port"]
    set(:pmdb) {pmdb_config}
    disable :logging
    disable :threaded
  end

  configure :development do
    register Sinatra::Reloader
  end

  get "/" do
    @movies = Yajl::Encoder.encode movies
    haml :index
  end

  get "/rescan" do
    content_type 'application/json', :charset => 'utf-8'
    Yajl::Encoder.encode rescan_movies
  end

  post "/remove" do
    hide_movie params["dir"], params["path"]
    "done"
  end

  get '/css/pmdb.css' do
    content_type 'text/css', :charset => 'utf-8'
    scss :pmdb
  end

  run! if app_file == $0 && $LOADED_FEATURES.all? {|f| f !~ %r{/exerb/mkexy.rb}}
end
