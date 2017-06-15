#!/Users/alex/.rvm/rubies/ruby-2.4.0/bin/ruby
require 'json'
require 'erb'
require 'set'
require 'tilt'
require 'fileutils'

VIEW_DIR = ARGV[0]
template_name = ARGV[1]
output_filename = ARGV[2]
context = STDIN.read

class Binder
  def initialize
    @orderables = Set.new(%i(name year rating rank time play_count album)).freeze
  end

  def get_binding
    return binding()
  end

  def partial(template_name)
    template_name = template_name.to_s + ".erb" if template_name.is_a? Symbol
    puts "Partial: " + @albums.class.to_s
    Tilt.new(VIEW_DIR + template_name).render(self)
  end

  def to_html(hash, key)
    raise TypeError unless hash.is_a? Hash
    raise TypeError unless key.is_a? Symbol
    items = nil
    value = hash[key]
    if value.is_a? Array
      value.map {|v| format_one(v, key)}.join("&NegativeMediumSpace;")
    else
      format_one(value, key)
    end
  end

  private
  def format_one(item, key)
    case item
      when Hash
        case key
          when :artist, :artists
            %(<a href="/i/artist/#{item[:id]}">
              <span class="label-artist label">#{item[:name].gsub(' ', '&nbsp;')}</span></a>)
          when :album
            %(<a href="/i/album/#{item[:id]}" class="label-album">#{item[:name]}</a>)
          when :tag
            %(<a href="/i/tag/#{item[:id]}" class="label-tag">#{item[:name]}</a>)
          else
            item.inspect
        end
      when Integer
        case key
          when :rating
            stars(item)
          when :time
            "#{item/60}:%02d" % (item%60)
          else
            item.to_s
        end
      when String, Symbol
        item.to_s
      when NilClass
        "nil:" + key.to_s
      else
        "#[#{item.class}: #{item.inspect}]"
    end
  end

  def stars(n)
    str = String.new
    str << %(<div class="rating" data-value="#{n}"><div class="rating-static">)
    # str << '★' * n
    # str << '☆' * (5-n)
    str << %(</div><div class="rating-active text-primary">)
    5.times do |i|
      str << %(<span data-num="#{5-i}">☆</span>) #5-1 because we're RTL here
    end
    str << %(</div></div>)
    str
  end

end

begin
  json = JSON.parse(context, symbolize_names: true) || {}
  json[:layout] = "layout.erb" unless json.has_key? :layout
  binder = Binder.new
  ivars = json.select {|k, _| k[0] == '@'}
  ivars&.each do |k, v|
    binder.instance_variable_set(k, v)
  end

  # bdng = binder.get_binding
  # json[:lvars]&.each do |k,v|
  #   bdng.local_variable_set(k, v)
  # end

  template = Tilt.new(VIEW_DIR + template_name)

  outstr = ""

  if layout = json[:layout]
    outstr = Tilt.new(VIEW_DIR + layout).render(binder) {template.render(binder)}
  else
    outstr = template.render(binder)
  end

  FileUtils.mkdir_p output_filename.sub(/\/[^\/]*$/, '')
  File.write(output_filename, outstr.gsub(/(?<=\A|\n)[ \t]*(?:\n|\z)/, ''))

rescue
  File.write(output_filename,
             "<h1>Rendering error: #{CGI::escapeHTML($!.message)}</h1>
  <pre>#{CGI::escapeHTML($!.backtrace.join("\n"))}</pre>")
  raise $!
end
