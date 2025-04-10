# frozen_string_literal: true

require_relative 'application_controller'

# Analyze Controller
class RoundupController < ApplicationController
  get '/' do
    locals = { title: 'Roundup', roundup_requested:
      app_helpers.roundup_requested?,
               git_commit: app_helpers.git_commit, }
    slim :'roundup.html', layout: :'layouts/default.html', locals: locals, pretty: true
  end

  # Trigger scrape endpoint
  post '/' do
    app_helpers.roundup_requested = true

    redirect '/'
  end
end
