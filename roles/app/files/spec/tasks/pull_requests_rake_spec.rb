# frozen_string_literal: true

require 'spec_helper'
require 'rake'
require_relative '../../app/tasks/pull_requests.rake'

RSpec.describe 'pull_requests.rake' do
  before do
    # Set up the Rake task
    Rake::Task.define_task(:environment)
  end
  
  describe 'pull_requests:update_metrics' do
    it 'calls update_pr_metrics on CoverageHistory' do
      expect(CoverageHistory).to receive(:update_pr_metrics).and_return(3)
      
      Rake::Task['pull_requests:update_metrics'].invoke
    end
  end
  
  describe 'pull_requests:validate' do
    it 'validates the pull requests YAML file' do
      # Set up our mocks
      validator = instance_double(PrValidatorService, errors: [])
      expect(PrValidatorService).to receive(:new).and_return(validator)
      expect(validator).to receive(:validate_pr_file).with(
        PrFileService::PR_FILE,
        anything
      ).and_return(true)
      
      # Should run without error
      expect { 
        Rake::Task['pull_requests:validate'].invoke
      }.not_to raise_error
    end
  end
  
  describe 'pull_requests:update_status' do
    it 'checks GitHub for PR status updates' do
      # Mock PullRequest import method
      expect(PullRequest).to receive(:import_from_file)
        .and_return({ imported: 0, updated: 0 })
      
      # Mock GitHub service
      github_service = instance_double(GithubPrService)
      expect(GithubPrService).to receive(:new).and_return(github_service)
      expect(github_service).to receive(:update_open_prs)
        .with(nil)
        .and_return({
          checked: 1,
          updated: 0,
          not_found: 0,
          errors: 0
        })
      
      # Run the task
      Rake::Task['pull_requests:update_status'].invoke
      
      # Reset for next test
      Rake::Task['pull_requests:update_status'].reenable
    end
    
    it 'updates metrics when PRs are updated' do
      # Mock PullRequest import method
      expect(PullRequest).to receive(:import_from_file)
        .and_return({ imported: 0, updated: 0 })
      
      # Mock GitHub service
      github_service = instance_double(GithubPrService)
      expect(GithubPrService).to receive(:new).and_return(github_service)
      expect(github_service).to receive(:update_open_prs)
        .with(nil)
        .and_return({
          checked: 1,
          updated: 1, # Indicates a PR was updated
          not_found: 0,
          errors: 0
        })
      
      # Should invoke the update_metrics task
      expect(CoverageHistory).to receive(:update_pr_metrics).and_return(1)
      
      # Run the task
      Rake::Task['pull_requests:update_status'].invoke
    end
    
    it 'respects the LIMIT environment variable' do
      # Set environment variable
      allow(ENV).to receive(:[]).with('LIMIT').and_return('5')
      
      # Mock PullRequest import method
      expect(PullRequest).to receive(:import_from_file)
        .and_return({ imported: 0, updated: 0 })
      
      # Mock GitHub service
      github_service = instance_double(GithubPrService)
      expect(GithubPrService).to receive(:new).and_return(github_service)
      expect(github_service).to receive(:update_open_prs)
        .with(5) # Should pass the limit
        .and_return({
          checked: 1,
          updated: 0,
          not_found: 0,
          errors: 0
        })
      
      # Run the task
      Rake::Task['pull_requests:update_status'].reenable
      Rake::Task['pull_requests:update_status'].invoke
    end
  end
end
