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

  def self.generate(pull_request_id = nil)
    if pull_request_id
      # Generate for a specific pull request
      pull_request = PullRequest.find_by(id: pull_request_id)
      return nil unless pull_request
      
      generate_for_pull_request(pull_request)
    else
      # Generate for all pull requests
      output_files = []
      PullRequest.find_each do |pull_request|
        result = generate_for_pull_request(pull_request)
        output_files << result[:output_file] if result
      end
      
      { count: output_files.size, output_files: output_files }
    end
  end
  
  private
  
  def self.generate_for_pull_request(pull_request)
    # Get all authorities for potential selection
    authorities = Authority.order(:short_name).to_a
    
    # Prepare data for the template
    locals = {
      pull_request: pull_request,
      authorities: authorities,
      title: "Pull Request ##{pull_request.id} - #{pull_request.title}"
    }
    
    output_file = render_to_file("pull_requests/#{pull_request.id}", 'pull_request', locals)
    log "Generated pull request page for ##{pull_request.id}"
    
    { pull_request: pull_request, output_file: output_file }
  end
end
