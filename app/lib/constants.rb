# frozen_string_literal: true

require_relative '../controllers/roundup_controller'
require_relative '../controllers/develop_controller'
require_relative '../controllers/webhooks_controller'

# Application wide constants
class Constants
  MORPH_URL = 'https://morph.io' #  / owner / repo / resource
  AUTHORITIES_URL = 'https://www.planningalerts.org.au/authorities'
  GITHUB_URL = 'https://github.com' # / owner / repo / resource
  PLANNIES_DOMAIN = ENV.fetch('PLANNIES_DOMAIN') { raise 'PLANNIES_DOMAIN not set' }

  PRODUCTION_OWNER = 'planningalerts-scrapers'
  MY_GITHUB_NAME = ENV.fetch('MY_GITHUB_NAME') { raise 'MY_GITHUB_NAME not set' }
  ISSUES_REPO = 'issues'

  ROUTES = [
    { path: '/app/roundup', controller: RoundupController },
    { path: '/webhooks', controller: WebhooksController },
    { path: '/', controller: DevelopController },
  ].freeze
end
