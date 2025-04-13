# frozen_string_literal: true

require_relative 'application_controller'

# Analyze Controller
class RoundupController < ApplicationController
  # Trigger scrape endpoint
  post '/' do
    app_helpers.roundup_requested = true

    redirect '/'
  end
end
