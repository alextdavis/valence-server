#!/Users/alex/.rvm/rubies/ruby-2.4.0/bin/ruby

MUSIC_BASE_URL = '//localhost'
VALENCE_DIR    = Dir.home = '/Music/Valence'

require 'json'
require 'bcrypt'
require 'uri'
require 'taglib'
require 'set'

class Ingester
  attr_reader :ignored_filetypes, :dupe_urls, :dupe_checksums
  attr_reader :found_titles, :missing_titles

  def initialize
    # mas = MediaAsset.select(:checksum, :url).all
    @existing_media_checksums = [] # Set.new(mas.map(&:checksum))
    @existing_media_urls = [] #Set.new(mas.map(&:url))
    @new_songs = []
    @dupe_urls = []
    @dupe_checksums = []
    @ignored_filetypes = {}
    @added_info = {}
    @found_titles = []
    @missing_titles = []
    @artwork_checksums = Set.new

    @output_json = []
  end

  def recursive_ingest(dirname)
    return if dirname == "Apple Music" || dirname == "Voice Memos"
    print '.'
    Dir.foreach dirname do |filename|
      next if filename == '.' || filename == '..' || filename == '.DS_Store'

      file = File.new("#{dirname}/#{filename}")
      if File.directory? file
        recursive_ingest(file.path)
      elsif filename.match(/\.(pdf|epub|ibooks|m4b|m4v|m4r|m4p)$/)
        @ignored_filetypes[$1] ||= 0
        @ignored_filetypes[$1] += 1
      elsif filename.match(/\.(m4a|mp3)$/)
        data = file.read
        checksum = Digest::MD5.base64digest(data)
        url = URI.escape(file.path.sub(/^.*\/Music\/iTunes Music/, "#{MUSIC_BASE_URL}/music"))
        if url.length > 512
          puts "\nFound url that's too long: \n#{url}\n"
          next
        end

        if @existing_media_urls.include? url
          @dupe_urls << file.path
          puts "Dupe URL #{url}: #{file.path}"
        end

        if @existing_media_checksums.include? checksum
          @dupe_checksums << file.path
          puts "Dupe Checksum #{checksum}: #{file.path}"
          next
        end

        new_song = {}
        TagLib::FileRef.open(file.path) do |fileref|
          unless fileref.null?
            tag = fileref.tag
            new_song[:title] = tag.title
            new_song[:artist] = tag.artist
            new_song[:album] = tag.album
            new_song[:year] = tag.year
            new_song[:track] = tag.track
            new_song[:genre] = tag.genre
            new_song[:comment] = tag.comment

            properties = fileref.audio_properties
            new_song[:length] = properties.length #=> 335 (song length in seconds)
          end
        end

        new_song[:title] ||= filename.match(/.*\/(\w+)\.\w+/)&[1]
        new_song[:title] ||= filename
        new_song[:artist] ||= "Unknown Artist"

        content_type = {'m4a' => 'audio/mp4a-latm', 'mp3' => 'audio/mpeg'}[filename.match(/\.(m4a|mp3)$/)[1]]

        out = {}

        out[:audio_asset] = {url: url, checksum: checksum, content_type: content_type}
        out[:album] = new_song[:album]

        if info_ary = @added_info[new_song[:title]]
          new_song[:rating] = info_ary[2].to_i / 20
          new_song[:rank] = info_ary[3] == '2' ? 3 : 2
          new_song[:play_count] = info_ary[9].to_i
          @found_titles << new_song[:title]
        else
          new_song[:rating] = 0
          new_song[:rank] = 2
          @missing_titles << new_song[:title]
        end

        out[:song] = {name: new_song[:title],
                      track: new_song[:track],
                      rating: new_song[:rating],
                      rank: new_song[:rank],
                      time: new_song[:length],
                      year: new_song[:year],
                      play_count: new_song[:play_count]}

        out[:artists] = []
        if new_song == nil
          puts "Song has no artists. Skipping:"
          puts new_song.inspect
        end
        new_song[:artist]&.split(/(?:, | and | & )/)&.each do |artist|
          out[:artists] << artist
        end

        tmp_filename = "/tmp/me.alextdavis.valence.ingest/artwork.jpg"

        unless ARGV[0] == "--no-thumbnails"
        `ffmpeg -y -loglevel quiet -i #{file.path.inspect} #{tmp_filename}`
        if File.readable?(tmp_filename)
          artwork_checksum = Digest::MD5.base64digest(File.read(tmp_filename))
          artwork_filename = "#{VALENCE_DIR}/Thumbnails/#{artwork_checksum.gsub('/', '_').gsub('+', '-').gsub('=', '')}.jpg"
          if @artwork_checksums.include? artwork_checksum
            `rm #{tmp_filename}`
          else
            `mv #{tmp_filename} #{artwork_filename}`
          end
          out[:artwork_asset] = {url: artwork_filename, checksum: artwork_checksum, content_type: 'image/jpeg'}
        end
        end

        @output_json << out
      else
        puts "Wrong file type: #{filename}"
      end
    end
  end

  def add_info(infostring)
    infostring.each_line do |str|
      ary = str.split("\t")
      @added_info[ary[0]] = ary
    end
  end

  def get_json
    JSON.generate(@output_json)
  end
end

i = Ingester.new
i.add_info(File.open("./Script/addtl_info.txt").read)
`mkdir /tmp/me.alextdavis.valence.ingest`


# puts "paste in extra data, followed by ^D"
# while true
#   line = gets
#   break if line == nil
#   i.add_info(line)
# end
i.recursive_ingest(File.expand_path(Dir.home + '/Music/iTunes Music'))
puts ''
puts i.ignored_filetypes
puts i.dupe_urls
puts i.dupe_checksums
puts "rating data could not be found for #{i.missing_titles.count} items"

File.write("./Script/rb_ingest_data.json", i.get_json)
