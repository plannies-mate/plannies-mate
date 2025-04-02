# frozen_string_literal: true

require_relative 'application_controller'

# Analyze Controller
class WebhooksController < ApplicationController
  post '/github' do
    payload = JSON.parse(request.body.read)
    event = request.env['HTTP_X_GITHUB_EVENT']

    if event == 'repository' && payload['action'] == 'created'
      repo_full_name = payload['repository']['full_name']

      # Create scraper record if it matches your criteria
      if should_track_repo?(repo_name)
        scraper = Scraper.create!(
          morph_url: "https://morph.io/#{repo_name}",
          github_url: payload['repository']['html_url'],
          url: payload['repository']['url'],
          needs_import: true,
          import_triggered_at: Time.current,
          import_trigger_reason: 'new_repo'
        )

        # Flag this new scraper to have a webhook added
        scraper.update(needs_webhook: true)
      end
    end

    status 200
  end
end
