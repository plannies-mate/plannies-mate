# frozen_string_literal: true

require 'octokit'

# Module providing common functionality for web scrapers
# use `extend ApplicationHelper` so everything (except InstanceMethods) become class methods
module GithubBase
  def owner
    'planningalerts-scrapers'
  end

  def issues_repo
    'issues'
  end

  # Create an Octokit Client
  def create_client
    token_name = 'GITHUB_PERSONAL_TOKEN'
    access_token = ENV.fetch(token_name, nil)
    if access_token.nil? && File.size?('.env')
      File.readlines('.env').each do |line|
        access_token = ::Regexp.last_match(1) if line =~ /#{token_name}=(.*)$/
      end
    end
    if access_token
      puts 'Creating client using personal token...'
      Octokit::Client.new(access_token: access_token, auto_paginate: true)
    else
      puts 'Creating client without authentication (rate limited to 60 calls per hour)'
      Octokit::Client.new auto_paginate: true
    end
  end

  # Instance Methods to be included
  module InstanceMethods
  end

  send :include, InstanceMethods

  def refresh_at
    secs_per_week = (60 * 60 * 24 * 7).to_i
    Time.now - secs_per_week
  end
end
