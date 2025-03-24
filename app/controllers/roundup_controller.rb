# frozen_string_literal: true

require_relative 'application_controller'

# Analyze Controller
class RoundupController < ApplicationController
  get '/' do
    locals = { title: 'Roundup', roundup_requested: app_helpers.roundup_requested? }
    slim :'roundup.html', layout: :'layout.html', locals: locals, pretty: true
  end

  # Trigger scrape endpoint
  post '/' do
    app_helpers.roundup_requested = true

    redirect '/'
  end
end
