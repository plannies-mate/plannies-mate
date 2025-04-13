# frozen_string_literal: true

require_relative 'application_controller'

# Analyze Controller
class RoundupController < ApplicationController
  # Trigger scrape endpoint
  post '/' do
    app_helpers.roundup_requested = true

    # Set the CSS status to requested
    css_dir = File.join(app_helpers.site_dir, 'assets', 'css')
    FileUtils.mkdir_p(css_dir)
    status_file = File.join(css_dir, 'update_status.css')

    FileUtils.rm_f(status_file)
    File.symlink('update_requested.css', status_file)

    redirect '/'
  end
end
