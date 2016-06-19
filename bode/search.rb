require "set"
require "find"
require "taglib"

module Search
  # search for all mp3 files at the location
  def self.get_mp3_files(location)
    Find.find(location) do |path|
      yield path if FileTest.file?(path) && File.extname(path) == ".mp3"
    end
  end
  # search for all mp3 files at the location and return the tags
  def self.get_tags(location)
    get_mp3_files(location) do |path|
      TagLib::MPEG::File.open(path) do |file|
        yield file.id3v2_tag
      end
    end
  end
  # search for all mp3 files at the location and read the tags for the artist
  # prioritize the album artist over the artist tag unless its empty or says "Various Artists"
  def self.get_artists(location)
    artists = Set.new
    get_tags(location) do |tag|
      # get artist and album artist
      # iTunes uses "TPE2" for album artist
      artist = tag.frame_list("TPE2").first.to_s
      # use artist tag if album artist empty or is "Various Artists" instead of album artist
      artist = tag.artist.to_s if artist == "" || artist == "Various Artists"
      # skip if it is still empty as there is no valid artist
      next if artist.empty?
      artists.add(artist)
    end
    # convert the set to an array so we can sort it
    artists.to_a.sort
  end
  # search for all mp3 files at the location and read the tags for all the titles
  def self.get_titles(location)
    titles = Set.new
    get_tags(location) do |tag|
      title = tag.title.to_s
      # skip if it is empty
      next if title.empty?
      titles.add(title)
    end
    # convert the set to an array so we can sort it
    titles.to_a.sort
  end
  # search for all mp3 files at the location and read the tags for all the albums
  def self.get_albums(location)
    albums = Set.new
    get_tags(location) do |tag|
      album = tag.album.to_s
      # skip if it is empty
      next if album.empty?
      albums.add(album)
    end
    # convert the set to an array so we can sort it
    albums.to_a.sort
  end
  # search for all mp3 files at the location and read the tags for all the genres
  def self.get_genres(location)
    genres = Set.new
    get_tags(location) do |tag|
      genre = tag.genre.to_s
      # skip if it is empty
      next if genre.empty?
      genres.add(genre)
    end
    # convert the set to an array so we can sort it
    genres.to_a.sort
  end
  # search for all mp3 files at the location and read the tags for all the years
  def self.get_years(location)
    years = Set.new
    get_tags(location) do |tag|
      year = tag.year.to_s
      # skip if it is empty
      next if year.empty?
      years.add(year)
    end
    # convert the set to an array so we can sort it
    years.to_a.sort
  end
  # search for all the mp3 files at the location and read the tags for all the comments
  def self.get_comments(location)
    comments = Set.new
    get_tags(location) do |tag|
      comment = tag.comment.to_s
      # skip if it is empty
      next if comment.empty?
      comments.add(comment)
    end
    # convert the set to an array so we can sort it
    comments.to_a.sort
  end
  # search for all the mp3 files at the location and read the tags and return abbrev.
  # details for each song
  def self.get_details(location)
    details = []
    get_tags(location) do |tag|
      details << {
        artist:       tag.artist.to_s,
        album:        tag.album,
        album_artist: tag.frame_list("TPE2").first.to_s,
        comment:      tag.comment.to_s,
        genre:        tag.genre.to_s,
        title:        tag.title.to_s,
        year:         tag.year.to_s
      }
    end
    details
  end
end
