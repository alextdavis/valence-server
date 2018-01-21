#!/usr/bin/env ruby
# frozen_string_literal: true

SRC_DIR = ARGV[0]
DEST_DIR = ARGV[1]
DATABASE_NAME = ARGV[2]
DO_THUMBS = ARGV.include? '--no-thumbnails'

require 'json'
require 'bcrypt'
require 'base64'
require 'uri'
require 'taglib'
require 'set'
require 'pg'

def md5_base64(filename)
  hex = `base64 -b #{filename}`.match(/^[0-9a-f]{32}/).to_i(16)
  urlsafe_base64(hex, false)
end

class Ingester
  attr_reader :ignored_filetypes, :dupe_urls, :dupe_checksums
  attr_reader :found_titles, :missing_titles

  def initialize
    # @new_songs = []
    @dupe_urls = []
    @dupe_checksums = []
    @ignored_filetypes = {}
    # @added_info = {}
    # @found_titles = []
    @missing_titles = []
    # @artwork_checksums = Set.new
    # @output_json = []
    @conn = DATABASE_NAME ? PG.connect(dbname: DATABASE_NAME) : nil
  end

  def image_asset_exists?(checksum)
    if @conn
      @conn.exec("select exists(select 1 from image_assets where checksum='#{checksum}')").res[0][0]
    else
      false
    end
  end

  def audio_asset_exists?(checksum)
    if @conn
      @conn.exec("select exists(select 1 from audio_assets where checksum='#{checksum}')").res[0][0]
    else
      false
    end
  end

  def ingest(filename)
    checksum = md5_base64 filename
    if audio_asset_exists? checksum
      @dupe_checksums << filename
      return
    end


    new_song = taglib_extract(filename)

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
                  disc: new_song[:disc], #!!
                  rating: new_song[:rating],
                  rank: new_song[:rank],
                  time: new_song[:length],
                  year: new_song[:year],
                  play_count: new_song[:play_count]}

    out[:artists] = []
    if new_song[:artist] == nil
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
        artwork_checksum = md5_base64 tmp_filename
        artwork_filename = "#{VALENCE_DIR}/Thumbnails/#{artwork_checksum.gsub('/', '_').gsub('+', '-').gsub('=', '')}.jpg"
        if image_asset_exists? artwork_checksum
          `rm #{tmp_filename}`
        else
          `mv #{tmp_filename} #{artwork_filename}`
        end
        out[:artwork_asset] = {url: artwork_filename, checksum: artwork_checksum, content_type: 'image/jpeg'}
      end
    end

    @output_json << out
  end

  def taglib_extract(filename)
    new_song = {}
    TagLib::FileRef.open(filename) do |fileref|
      unless fileref.null?
        tag = fileref.tag
        new_song[:title] = tag.title
        new_song[:artist] = tag.artist
        new_song[:album] = tag.album
        new_song[:year] = tag.year
        new_song[:track] = tag.track
        new_song[:genre] = tag.genre
        new_song[:comment] = tag.comment

        new_song[:length] = fileref.audio_properties.length
      end
    end
    new_song
  end

  def recursive_find(dirname)
    return if ['Apple Music', 'Voice Memos'].include? dirname
    print '.'
    Dir.foreach dirname do |filename|
      next if %w(. .. .DS_Store).include? dirname

      file = File.open("#{dirname}/#{filename}")
      if File.directory? file
        recursive_find file.path
      elsif filename.match(/\.(pdf|epub|ibooks|m4b|m4v|m4r|m4p)$/)
        @ignored_filetypes[$1] ||= 0
        @ignored_filetypes[$1] += 1
      elsif filename.match(/\.(m4a|mp3)$/)
        ingest(file)
      else
        puts "Wrong file type: #{filename}"
      end
      file.close
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
i.recursive_ingest(File.expand_path(Dir.home + '/Music/iTunes/iTunes Music'))
puts ''
puts i.ignored_filetypes
puts i.dupe_urls
puts i.dupe_checksums
puts "rating data could not be found for #{i.missing_titles.count} items"

File.write("./Script/rb_ingest_data.json", i.get_json)
