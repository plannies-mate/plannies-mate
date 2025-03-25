# frozen_string_literal: true

# config.ru

require_relative 'app'
require_gems_for(:app)

App.configure_sinatra_options(self)
App.configure_sinatra_routes(self)

run Sinatra::Application
