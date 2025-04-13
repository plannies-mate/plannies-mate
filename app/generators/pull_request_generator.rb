# frozen_string_literal: true

require 'tilt'
require 'slim'
require_relative '../helpers/application_helper'
require_relative '../models/pull_request'
require_relative 'generator_base'

# Generates `site_dir/pull_requests/ID.html` page for each pull request
class PullRequestGenerator
  extend GeneratorBase
  extend ApplicationHelper

  def self.generate
    # Generate for all pull requests
    output_files = []
    PullRequest.find_each do |pull_request|
      result = generate_for_pull_request(pull_request)
      output_files << result[:output_file] if result
    end

    { count: output_files.size, output_files: output_files }
  end

  def self.generate_for_pull_request(pull_request)
    # Get all authorities for potential selection
    authorities = Authority.order(:short_name).to_a

    # Prepare data for the template
    locals = {
      pull_request: pull_request,
      authorities: authorities,
      title: "Pull Request ##{pull_request.id} - #{pull_request.title}",
    }

    output_file = render_to_file('pull_request', "pull_requests/#{pull_request.id}", locals)
    log "Generated pull request page for ##{pull_request.id}"

    { pull_request: pull_request, output_file: output_file }
  end
end
