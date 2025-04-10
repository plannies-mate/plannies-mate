# frozen_string_literal: true

require_relative 'application_controller'

require 'sinatra/json'

# Development / debug endpoints not visible from outside
class DevelopController < ApplicationController
  NOT_FOUND_PATH = '/errors/404.html'

  # We're already using Sinatra::JSON from contrib
  # register Sinatra::Contrib

  get '/debug' do
    locals = { title: 'APP Endpoints',
               get_paths: get_paths,
               post_paths: method_paths('POST'),
               env: ENV.fetch('RACK_ENV', nil),
               roundup_request_file: app_helpers.roundup_request_file,
               roundup_request_file_exists: File.exist?(app_helpers.roundup_request_file), }
    app_helpers.render 'debug', locals
  end

  private

  def get_paths
    paths = method_paths('GET')
    paths << '/index.html'
    paths << '/authorities'
    paths << '/crikey-whats-that'
    paths << '/scrapers'
    paths << '/repos'
    paths << '/robots.txt'
    paths
  end

  def method_paths(http_method)
    paths =
      Constants::ROUTES.map do |route|
        route[:controller].routes[http_method]&.map do |r|
          "#{route[:path]}#{r[0]}".sub(%r{\A/+}, '/').sub(%r{(?!^)/\z}, '')
        end
      end
    paths.flatten.compact.sort
  end
end
