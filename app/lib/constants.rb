# frozen_string_literal: true

require_relative '../controllers/roundup_controller'
require_relative '../controllers/health_controller'
require_relative '../controllers/develop_controller'
require_relative '../controllers/pull_requests_controller'
require_relative '../controllers/webhooks_controller'

# Application wide constants
class Constants
  PRODUCTION_OWNER = 'planningalerts-scrapers'
  ISSUES_REPO = 'issues'

  ROUTES = [
    { path: '/app/health', controller: HealthController },
    { path: '/app/roundup', controller: RoundupController },
    { path: '/app/pull_requests', controller: PullRequestsController },
    { path: '/webhooks', controller: WebhooksController },
    { path: '/', controller: DevelopController },
  ].freeze
end
