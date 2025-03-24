# tasks.rb
#
# Require what background rake tasks require

require_relative 'config/boot'

require_relative 'app/lib/app_helpers_accessor'
require_relative 'app/lib/constants'
# Initializers
Dir.glob(File.join(File.dirname(__FILE__), 'config/initializers/*.rb')).each { |file| require file }

# pull in the models, helpers and controllers, they will pull in what they need
Dir.glob(File.join(File.dirname(__FILE__),
                   'app/{helpers,models,fetchers,generators,importers,lib,matchers,services}/**/*.rb')).each do |file|
  require file
end

# Application Class
class App
  extend AppHelpersAccessor
end
