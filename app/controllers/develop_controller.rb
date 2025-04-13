# frozen_string_literal: true

require_relative 'application_controller'

require 'sinatra/json'

# Development / debug endpoints not visible from outside
class DevelopController < ApplicationController
  NOT_FOUND_PATH = '/errors/404.html'

  # We're already using Sinatra::JSON from contrib
  # register Sinatra::Contrib

  get '/' do
    "Hello #{ENV.fetch('RACK_ENV', 'development')}!"
  end
end
