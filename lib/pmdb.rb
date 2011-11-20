require 'bundler'
Bundler.setup
require 'sinatra/base'
require 'sinatra/reloader'
require 'haml'
require 'compass'
require 'yaml'
require 'pathname'

class IMDb
  def initialize(file)
    @file = file
  end

  def parse
    @url = parse_url_from_file
    name = ""
    unless @url
      name = parse_name_and_year_from_dir
      @url = url_from name
    end
    parse_name_and_url_from_dir
    @name, @score, @votes, @genres = parse_data_from_imdb
  end

  private

  def parse_url
    return unless file.extname =~ /\.nfo$/i

    urls = URI.extract(@file.read, "http")
    urls.detect {|url| url =~ /imdb/i}
  end

  def parse_name_from_dir
    dir = file.dirname.basename.to_s.gsub(/['"]/, "")
    year = dir.scan(/\s?((?:19|20)\d{2})/).flatten.last

    name = ""
    if year
      name_without_year = dir.gsub(/\s?#{year}.*/, "")
      unless name_without_year.empty?
        name = "#{name_without_year} (#{year})"
      end
    end
    @url = URI.escape("http://akas.imdb.com/find?s=all&x=0&y=0&q=#{@name}")
  end
end

class MovieFinder
  def initialize(options)
    @options = options
  end

  def movies
    parse_imdb_info(objectify(files(directories)))
  end

  private
  
  def directories
    @options["dirs"].reduce([]) do |memo, dir|
      memo << Pathname.new(dir).children.select(&:directory?)
    end.flatten
  end

  def files(dirs)
    dirs.reduce([]) do |memo, dir|
      file = dir.children.detect do |f|
        next unless f.file?
        f.extname =~ /\.(nfo|mkv|avi|mp4)$/i
      end
      memo << file
    end
  end

  def objectify(files)
    files.map do |f|
      {imdb: IMDb.new(f), path: f.to_s, mtime: f.mtime}
    end
  end

  def parse_imdb_info(objs)

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
    puts MovieFinder.new(settings.pmdb).movies
    haml :index
  end

  get '/css/pmdb.css' do
    content_type 'text/css', :charset => 'utf-8'
    scss :pmdb
  end

  run! if app_file == $0
end
