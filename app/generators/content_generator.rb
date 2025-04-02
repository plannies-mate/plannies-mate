# frozen_string_literal: true

require 'tilt'
require 'slim'

require_relative '../helpers/application_helper'
require_relative '../models/authority'
require_relative 'generator_base'

# Generates static content under `site_dir`:
# * recursively copies `public/` to `site_dir` AND
# * app/contents wrapped in a layout
class ContentGenerator
  extend GeneratorBase
  extend ApplicationHelper

  def self.generate_public
    source_dir = File.join(root_dir, 'public')
    Dir.glob('**/*', base: source_dir).each do |relative_path|
      source_path = File.join(source_dir, relative_path)
      target_path = File.join(site_dir, relative_path)

      next unless File.file?(source_path)

      # Create the necessary directory structure in the target path
      FileUtils.mkdir_p(File.dirname(target_path))
      # Copy the file
      FileUtils.cp(source_path, target_path)
    end
  end

  def self.generate_contents
    source_dir = File.join(root_dir, 'app/contents')
    Dir.glob('**/*.html', base: source_dir).each do |relative_path|
      source_path = File.join(source_dir, relative_path)
      target_path = File.join(site_dir, relative_path)

      next unless File.file?(source_path)

      FileUtils.mkdir_p(File.dirname(target_path))
      render_content target_path,
                     title: File.basename(relative_path, '.html'),
                     no_menu: (relative_path == 'index.html'),
                     body: File.read(source_path)
    end
  end

  def self.render_content(target_path, no_menu:, body:, title:, pretty: true)
    layout_path = File.join(views_dir, 'layouts', 'default.html.slim')
    layout_template = Slim::Template.new(layout_path, pretty: pretty)
    locals = { title: title, no_menu: no_menu }
    content = layout_template.render(self, locals) { body }
    File.write(target_path, content)
  end
end
