# frozen_string_literal: true

require_relative 'application_controller'

# Health Controller
class HealthController < ApplicationController
  # Return health information in a json object
  get '/' do
    content_type '.txt'

    'OK'
  end
end
