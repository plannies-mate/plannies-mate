# frozen_string_literal: true

require_relative '../controllers/roundup_controller'
require_relative '../controllers/health_controller'
require_relative '../controllers/develop_controller'

# Application wide constants
class Constants
  ROUTES = [
    { path: '/app/health', controller: HealthController },
    { path: '/app/roundup', controller: RoundupController },
    { path: '/', controller: DevelopController },
  ].freeze
end
