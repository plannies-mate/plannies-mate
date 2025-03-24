# frozen_string_literal: true

require 'spec_helper'
require 'rake'

RSpec.describe 'pull_requests.rake' do
  before do
    Rake::Task.tasks.each(&:reenable)
    Rake::Task.load_tasks if Rake::Task.tasks.empty?
  end

  after do
    RSpec::Mocks.space.reset_all
    Rake::Task.tasks.each(&:reenable)
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
      expect do
        Rake::Task['pull_requests:validate'].invoke
      end.not_to raise_error
    end
  end

  describe 'pull_requests:update_status' do
    it 'checks GitHub for PR status updates' do
      # Mock services
      class_double(PrFileService)
      github_service = instance_double(GithubPrService)

      # Set up expectations
      expect(PrFileService).to receive(:read_file).and_return([
                                                                {
                                                                  'title' => 'Test PR',
                                                                  'url' => 'https://github.com/test/repo/pull/1',
                                                                },
                                                              ])

      expect(GithubPrService).to receive(:new).and_return(github_service)

      expect(github_service).to receive(:parse_github_url)
        .with('https://github.com/test/repo/pull/1')
        .and_return({
                      owner: 'test',
                      repo: 'repo',
                      pr_number: '1',
                    })

      expect(github_service).to receive(:check_pr_status)
        .with('test', 'repo', '1')
        .and_return({
                      'state' => 'closed',
                      'closed_at' => '2025-03-24T12:00:00Z',
                      'merged' => true,
                    })

      expect(PrFileService).to receive(:update_pr_status)
      expect(PrFileService).to receive(:save_file)

      # Task will call update_metrics at the end
      expect(CoverageHistory).to receive(:update_pr_metrics).and_return(0)

      # Run the task
      Rake::Task['pull_requests:update_status'].invoke
    end
  end
end
