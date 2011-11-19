require 'bundler'
Bundler.setup
require 'sinatra/base'
require 'sinatra/reloader'
require 'haml'
require 'compass'
require 'yaml'
require 'pathname'

class MovieFinder
  def initialize(options)
    @options = options
  end

  def find
    dirs = @options["dirs"].reduce([]) do |memo, dir|
      memo << Pathname.new(dir).children.select(&:directory?)
    end.flatten
  end
end

class PMDb < Sinatra::Base
  helpers do
    class << self
      def pmdb_config
        YAML.load(File.read(File.dirname(__FILE__) + '/../config.yaml'))
      end
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
    enable :logging
  end

  configure :development do
    register Sinatra::Reloader
  end

  get "/" do
    p settings.pmdb
    puts MovieFinder.new(settings.pmdb).find
    haml :index
  end

  get '/css/pmdb.css' do
    content_type 'text/css', :charset => 'utf-8'
    scss :pmdb
  end

  run! if app_file == $0
end
