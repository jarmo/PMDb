class IMDb
  attr_reader :url, :movie_id, :year, :name, :score, :votes, :plot, :genres

  def initialize(file)
    @year = @name = @score = @votes = @plot = @genres = "N/A"
    @file = file
    parse_file file
    parse_imdb
  end

  def to_json
    Yajl::Encoder.encode :url => url, :movie_id => movie_id, :year => year, :plot => plot,
                         :name => name, :score => score, :votes => votes, :genres => genres
  end

  private

  def parse_file(file)
    @url = parse_url file
    @movie_id = @url.split("/").last if @url
    @name, @year = parse_name_and_year file
  end

  def parse_imdb
    suffix = @movie_id ? "i=#{@movie_id}" : "t=#{@name}&y=#{@year}"
    scraping_url = URI.encode "http://imdbapi.com/?#{suffix}"    
    parse_response Net::HTTP.get_response(URI.parse(scraping_url)).body
  rescue Exception => e
    puts "Got error while trying to fetch imdb info: #{e.message}"
  end

  def parse_response response
    json = Yajl::Parser.parse response, :symbolize_keys => true
    return unless json[:Response] == "True"

    @name = json[:Title]
    @year = json[:Year]
    @score = json[:Rating]
    @votes = json[:Votes].reverse.gsub(/(\d{3})/, '\1 \2').reverse.strip
    @plot = json[:Plot]
    @genres = json[:Genre]
    @movie_id = json[:ID]
    @url = "http://akas.imdb.com/title/#{@movie_id}"
  end

  def parse_url(file)
    return unless file.nfo?

    urls = URI.extract(@file.read, "http")
    urls.detect {|url| url =~ /imdb/i}
  end

  #def url_from(name)
    #URI.escape("http://akas.imdb.com/find?s=all&x=0&y=0&q=#{name}")
  #end

  def parse_name_and_year(file)
    name = clean_dir(file)
    year = name.scan(/\s?((?:19|20)\d{2})/).flatten.last
    if year
      name_without_year = name.gsub(/\s?#{year}$/, "")
      name = name_without_year unless name_without_year.empty?
    end
    return name, year
  end

  def clean_dir(file)
    excluded_keywords = %w(
      unrated 720p 1080p 1080i repack rerip
      retail r5 dvd limited ee ts proper tc fs ws bluray hddvd subpack
      xvid divx dvdrip dvdscr xxx hdtv internal
      telesync subfix dirfix screener scr cam nfofix readnfo dsr workprint mdvdr bdrip
      stv extended dvdrscreener dvdscreener bdscr)

    parent_dirname = file.dirname.basename.to_s.gsub(/['"]/, "").gsub(/[-._]/, " ").squeeze(" ")
    excluded_regexp = /^(?:\(incomplete\)-)?(.*?)(?:#{excluded_keywords.join(" | ")})/i
    matched_name = parent_dirname.scan(excluded_regexp).flatten.first
    matched_name || parent_dirname
  end
end
