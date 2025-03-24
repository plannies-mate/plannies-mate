# frozen_string_literal: true

# View Helper methods and CONSTANTS
module SlimHelper
  # Render a template with layouts and write to a file
  def render(view, locals = {})
    # Add default locals that all templates need
    locals[:title] ||= view.capitalize
    layout = (locals[:layout] || 'layout').to_s
    pretty = locals.fetch(:pretty, true)

    # Get the template paths
    template_path = add_slim_extensions File.join(views_dir, view)
    layout_path = add_slim_extensions File.join(views_dir, layout)

    # Render the template with the layout
    template = Slim::Template.new(template_path, pretty: pretty)
    layout = Slim::Template.new(layout_path, pretty: pretty)

    content = template.render(self, locals)
    layout.render(self, locals) { content }
  end

  # Add a method to render slim partials
  def render_partial(partial, locals = {})
    partial = partial.to_s.sub(/^:/, '')

    template_path = add_slim_extensions File.join(views_dir, partial)
    template = Slim::Template.new(template_path, pretty: true)

    template.render(self, locals)
  end

  def add_slim_extensions(path)
    ['', '.slim', '.html.slim'].each do |suffix|
      this_path = "#{path}#{suffix}"
      return this_path if File.exist?(this_path)
    end
    path
  end
end
