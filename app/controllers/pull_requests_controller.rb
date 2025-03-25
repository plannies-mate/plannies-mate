# frozen_string_literal: true

require_relative 'application_controller'

# Controller for managing GitHub Pull Requests
class PullRequestsController < ApplicationController
  get '/' do
    # Get all pull requests, sorted by creation date (newest first)
    pull_requests = PullRequest.order(created_at: :desc).to_a
    
    locals = { 
      title: 'Pull Requests',
      pull_requests: pull_requests
    }
    
    app_helpers.render 'pull_requests', locals
  end
  
  get '/:id' do
    # Find the requested pull request
    pull_request = PullRequest.find(params[:id])
    
    # Get all authorities for selection
    authorities = Authority.order(:short_name).to_a
    
    locals = {
      title: "Edit Pull Request ##{pull_request.id}",
      pull_request: pull_request,
      authorities: authorities
    }
    
    app_helpers.render 'pull_request', locals
  end
  
  post '/:id' do
    pull_request = PullRequest.find(params[:id])
    
    # Update the authorities association
    authority_ids = params[:authority_ids] || []
    pull_request.authorities = Authority.where(id: authority_ids)
    
    # Redirect back to the pull request list
    redirect '/app/pull_requests'
  end
end
