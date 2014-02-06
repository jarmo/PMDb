require "bundler"
Bundler.require

require_relative 'pathname_ext'
require_relative 'movie_finder'
require_relative 'movie'
require_relative 'temporary_movie'

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

    def add_temporary list
      MovieFinder.new(settings.pmdb).temporary list
    end
  end

  configure do
    Compass.configuration do |config|
      config.project_path = File.dirname(__FILE__)
      config.sass_dir = 'views'
      config.output_style = :compressed
    end

    set :haml, {:format => :html5}
    set :scss, Compass.sass_engine_options
    set :port, pmdb_config["port"]
    set(:pmdb) {pmdb_config}
    disable :logging
    disable :threaded
  end

  get "/" do
    @movies = MultiJson.dump movies
    haml :index
  end

  get "/rescan" do
    content_type 'application/json', :charset => 'utf-8'
    MultiJson.dump rescan_movies
  end

  post "/remove" do
    hide_movie params["dir"], params["path"]
    "done"
  end

  get "/temporary" do
    content_type 'application/json', :charset => 'utf-8'
    Yajl::Encoder.encode add_temporary(params["list"])
  end

  get '/css/pmdb.css' do
    content_type 'text/css', :charset => 'utf-8'
    scss :pmdb
  end

  if $LOADED_FEATURES.any? {|f| f =~ %r{/exerb/mkexy.rb}}
    # make sure that at least one request has been done to trigger all
    # autoloads for exerb
    Thread.new do
      loop do
        begin
          Net::HTTP.get_response(URI.parse('http://localhost:7000'))
          break
        rescue Exception
          sleep 1
        end
      end
      exit
    end
  end

  run! if app_file == $0
end
