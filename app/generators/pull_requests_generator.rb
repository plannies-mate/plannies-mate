# frozen_string_literal: true

require 'tilt'
require 'slim'
require_relative '../helpers/application_helper'
require_relative '../models/pull_request'
require_relative 'generator_base'

# Generates `site_dir/pull_requests.html` with the list of pull requests
class PullRequestsGenerator
  extend GeneratorBase
  extend ApplicationHelper

  def self.generate
    # Get all pull requests ordered by creation date (newest first)
    pull_requests = PullRequest.order(created_at: :desc).to_a
    
    return nil if pull_requests.empty?
    
    # Prepare data for the template
    locals = {
      pull_requests: pull_requests,
      title: 'Pull Requests'
    }
    
    locals[:output_file] = render_to_file('pull_requests', 'pull_requests', locals)
    log "Generated pull requests page with #{pull_requests.size} pull requests"
    locals
  end
end
