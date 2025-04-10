# tasks.rb
#
# Require what background rake tasks require

require_relative 'config/boot'

require_relative 'app/lib/app_helpers_accessor'
require_relative 'app/lib/constants'
# Initializers
Dir.glob(File.join(File.dirname(__FILE__), 'config/initializers/*.rb')).each { |file| require file }

# pull in the models, helpers and controllers, they will pull in what they need
glob_pattern = 'app/{helpers,models,fetchers,generators,importers,lib,analyzers,matchers,services}/**/*.rb'
Dir.glob(File.join(File.dirname(__FILE__), glob_pattern)).each do |file|
  require file
end

# Application Class
class App
  extend AppHelpersAccessor
end
