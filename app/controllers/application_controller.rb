# frozen_string_literal: true

# application_controller.rb

require 'json'
require 'sinatra/base'
require_relative '../lib/app_helpers_accessor'

# Base Controller for Sinatra APP Application
class ApplicationController < Sinatra::Base
  include AppHelpersAccessor

  # don't enable logging when running tests
  configure :production, :development do
    enable :logging
  end
end
