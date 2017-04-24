#!/Users/alex/.rvm/rubies/ruby-2.4.0/bin/ruby
require 'json'
require 'erb'
require 'tilt'

VIEW_DIR = ARGV[0]
template_name = ARGV[1]
context = ARGV[2]

class Binder
  def get_binding
    return binding()
  end

  def partial(template_name)
    template_name = template_name.to_s + ".erb" if template_name.is_a? Symbol
    Tilt.new(VIEW_DIR + template_name).render
  end
end

def log(thing)
  $stderr.puts(thing)
end


json = JSON.parse(context, symbolize_names: true) || {}

json[:layout] = "layout.erb" unless json.has_key? :layout

binder = Binder.new

ivars = json.select {|k,_| k[0] == '@'}

ivars&.each do |k,v|
  binder.instance_variable_set(k, v)
end

bdng = binder.get_binding

# json[:lvars]&.each do |k,v|
#   bdng.local_variable_set(k, v)
# end

template = Tilt.new(VIEW_DIR + template_name)

if layout = json[:layout]
  puts Tilt.new(VIEW_DIR + layout).render(binder) { template.render(binder) }
else
  puts template.render(binder)
end
