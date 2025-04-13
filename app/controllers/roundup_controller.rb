# frozen_string_literal: true

require_relative 'application_controller'

# Analyze Controller
class RoundupController < ApplicationController
  # Trigger scrape endpoint
  post '/' do
    app_helpers.roundup_requested!
    redirect request.referer.presence || '/'
  end
end
