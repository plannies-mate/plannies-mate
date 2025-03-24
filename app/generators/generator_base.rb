# frozen_string_literal: true

require 'slim'
require 'json'
require 'fileutils'
require 'date'

require_relative '../lib/app_helpers_accessor'
# Module providing common functionality for generators
#
# use `extend GeneratorBase` so everything become class methods
module GeneratorBase
  include AppHelpersAccessor

  # Render a template with layouts and write to a file
  def render_to_file(view, url_path, locals = {})
    output = app_helpers.render(view, locals)

    output_filename = File.join(app_helpers.site_dir, "#{url_path}.html")
    FileUtils.mkdir_p(File.dirname(output_filename))
    File.write(output_filename, output)

    log "Generated: #{output_filename}"
    output_filename
  end
end
