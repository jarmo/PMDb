module PMDbPathname
  def video?
    extname =~ /\.(mkv|avi|mp4)$/i
  end

  def nfo?
    extname =~ /\.nfo$/i
  end
end

class Pathname
  include PMDbPathname
end
