# frozen_string_literal: true

# app.rb
#
# Require what web app needs

require_relative 'config/boot'

require 'sinatra'
require 'sinatra/json' # See https://sinatrarb.com/contrib/json
# require 'sinatra/contrib' # See https://sinatrarb.com/contrib/
require 'sinatra/activerecord'

require_relative 'app/lib/app_helpers_accessor'
require_relative 'app/lib/constants'

# Initializers
Dir.glob(File.join(File.dirname(__FILE__), 'config/initializers/*.rb')).each { |file| require file }

# pull in the models, helpers and controllers, they will pull in what they need
Dir.glob(File.join(File.dirname(__FILE__), 'app/{helpers,models,controllers}/*.rb')).each { |file| require file }

# Application Class
class App
  extend AppHelpersAccessor

  def self.configure_sinatra_options(klass)
    klass.send :set, :root, File.dirname(__FILE__)
    views_path = File.expand_path('app/views', __dir__)
    klass.send :set, :views, views_path

    klass.send :set, :default_content_type, :html
    klass.send :set, :public_folder, App.app_helpers.site_dir
    klass.send :set, :database_file, File.expand_path('config/database.yml', __dir__)

    klass.send :enable, :static
  end

  def self.configure_sinatra_routes(klass)
    # map the controllers to routes
    Constants::ROUTES.each do |route|
      klass.send(:map, route[:path]) { run route[:controller] }
    end
  end
end
