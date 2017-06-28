# require "vapor_tilt_adapter/version"
require 'cgi'
require 'fileutils'
require 'json'
require 'English'

module VaporTiltAdapter
  class Renderer
    def render(view_dir, template_filename, output_path, context, default_layout = "layout.erb")
      json          = JSON.parse(context, symbolize_names: true) || {}
      json[:layout] = default_layout unless json.key? :layout

      ivars = json.select { |k, _| k[0] == '@' }
      ivars&.each do |k, v|
        instance_variable_set(k, v)
      end

      template = Tilt.new(view_dir + template_filename)

      outstr = if (layout = json[:layout])
                 Tilt.new(view_dir + layout).render(self) { template.render(self) }
               else
                 template.render(self)
               end

      FileUtils.mkdir_p output_path.sub(%r{/[^/]*$}, '')
      File.write(output_path, outstr)
    rescue
      write_error(output_path, $ERROR_INFO)
      raise $ERROR_INFO
    end

    protected

    def write_error(output_path, error)
      File.write(output_path, "<h1>Rendering error: #{CGI.escapeHTML(error.message)}</h1>" \
                                  "<pre>#{CGI.escapeHTML(error.backtrace.join("\n"))}</pre>")
      # TODO: add more debug information in the case of an error
      # TODO: make the presence of debug information be dependent on dev/production environment
    end
  end
end
