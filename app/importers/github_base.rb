# frozen_string_literal: true

require 'octokit'

# Module providing common functionality for web scrapers
# use `extend ApplicationHelper` so everything (except InstanceMethods) become class methods
module GithubBase
  # Create an Octokit Client
  def create_client
    token_name = 'GITHUB_PERSONAL_TOKEN'
    access_token = ENV.fetch(token_name) { raise "Missing #{token_name}" }

    puts "Creating client using #{token_name} ..."
    client = Octokit::Client.new(access_token: access_token, auto_paginate: true)

    # Verify the access token belongs to the right user
    verify_org_access(client, Constants::PRODUCTION_OWNER)
    client
  end

  def refresh_at
    secs_per_week = (60 * 60 * 24 * 7).to_i
    Time.now - secs_per_week
  end

  def verify_org_access(client, org)
    authenticated_user = client.user
    puts "Authenticated as: #{authenticated_user.login}, checking access to org: #{org}"
    # Try to get the user's membership in the organization
    membership = client.organization_membership(org)
    puts "✅ Successfully verified membership in #{org} organization as #{membership.role}"
  rescue Octokit::NotFound, Octokit::Forbidden
    puts "❌ Token does not have access to organization #{org}"
    puts "   Please use a classic token with 'repo' and 'read:org' scopes"
    # raise
  end
end
