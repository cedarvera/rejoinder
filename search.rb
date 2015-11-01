require "set"
require "find"
require "taglib"

module Search
  # search for all mp3 files at the location and read the tags for the artist
  # prioritize the album artist over the artist tag unless its empty or says "Various Artists"
  def self.artists(location)
    artists = Set.new
    Find.find(location) do |path|
      # only look at mp3 files
      if FileTest.file?(path) && File.extname(path) == ".mp3"
        TagLib::MPEG::File.open(path) do |file|
          # get artist and album artist
          tag = file.id3v2_tag
          # iTunes uses "TPE2" for album artist
          artist = tag.frame_list("TPE2").first.to_s
          # use artist tag if empty or is "Various Artists" instead of album artist
          if artist == "" || artist == "Various Artists"
            # try the artist property
            artist = tag.artist.to_s
            # only add if not empty
            if artist != ""
              artists.add(artist)
            end
          else
            artists.add(artist)
          end
        end
      end
    end
    # Convert the set to an array so we can sort it
    artists.to_a.sort
  end
end
