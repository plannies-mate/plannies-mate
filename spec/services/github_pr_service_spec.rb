# frozen_string_literal: true

require 'spec_helper'
require 'net/http'
require_relative '../../app/services/github_pr_service'

RSpec.describe GithubPrService do
  let(:service) { described_class.new }

    describe '#check_pr_status' do
    let(:mock_response) do
      instance_double(
        Net::HTTPResponse,
        code: '200',
        body: {
          state: 'closed',
          closed_at: '2025-03-15T12:00:00Z',
          merged: true,
        }.to_json
      )
    end

    it 'makes a request to GitHub API and returns parsed JSON' do
      allow_any_instance_of(Net::HTTP).to receive(:request).and_return(mock_response)

      result = service.check_pr_status('owner', 'repo', '123')

      expect(result['state']).to eq('closed')
      expect(result['merged']).to eq(true)
    end

    it 'raises error for non-200 responses' do
      error_response = instance_double(
        Net::HTTPResponse,
        code: '404',
        message: 'Not Found',
        body: ''
      )

      allow_any_instance_of(Net::HTTP).to receive(:request).and_return(error_response)

      expect { service.check_pr_status('owner', 'repo', '123') }.to raise_error(StandardError)
    end

    it 'adds rate limit message for 403 responses with rate limit' do
      rate_limit_response = instance_double(
        Net::HTTPResponse,
        code: '403',
        message: 'Forbidden',
        body: 'API rate limit exceeded'
      )

      allow_any_instance_of(Net::HTTP).to receive(:request).and_return(rate_limit_response)

      expect { service.check_pr_status('owner', 'repo', '123') }.to raise_error(/Rate limit exceeded/)
    end
  end

  describe '#update_open_prs' do
    before do
      PullRequest.destroy_all
    end

    let!(:pr1) do
      PullRequest.create!(
        url: 'https://github.com/owner/repo/pull/1',
        title: 'Test PR 1',
        created_at: Date.today,
        github_owner: 'owner',
        github_repo: 'repo',
        pr_number: 1,
        needs_github_update: true
      )
    end

    let!(:pr2) do
      PullRequest.create!(
        url: 'https://github.com/owner/repo/pull/2',
        title: 'Test PR 2',
        created_at: Date.today,
        github_owner: 'owner',
        github_repo: 'repo',
        pr_number: 2,
        needs_github_update: false # Already updated, should be skipped
      )
    end

    it 'only updates PRs that need updates' do
      allow(service).to receive(:check_pr_status)
        .with('owner', 'repo', 1)
        .and_return({
                      'state' => 'closed',
                      'closed_at' => '2025-03-24T12:00:00Z',
                      'merged' => true,
                    })

      # Should not be called for pr2
      expect(service).not_to receive(:check_pr_status).with('owner', 'repo', 2)

      result = service.update_open_prs

      expect(result[:checked]).to eq(1)
      expect(result[:updated]).to eq(1)

      # Verify pr1 was updated
      pr1.reload
      expect(pr1.closed_at_date).to eq(Date.parse('2025-03-24'))
      expect(pr1.accepted).to be true
      expect(pr1.needs_github_update).to be false
    end

    it 'respects the limit parameter' do
      # Add a third PR
      PullRequest.create!(
        url: 'https://github.com/owner/repo/pull/3',
        title: 'Test PR 3',
        created_at: Date.today,
        github_owner: 'owner',
        github_repo: 'repo',
        pr_number: 3,
        needs_github_update: true
      )

      # Mock check_pr_status to return an open PR
      allow(service).to receive(:check_pr_status)
        .and_return({
                      'state' => 'open',
                      'merged' => false,
                    })

      # Should only check one PR
      expect(service).to receive(:check_pr_status).once

      result = service.update_open_prs(1)

      expect(result[:checked]).to eq(1)
    end

    it 'handles errors gracefully' do
      allow(service).to receive(:check_pr_status)
        .with('owner', 'repo', 1)
        .and_raise(StandardError.new('API error'))

      result = service.update_open_prs

      expect(result[:checked]).to eq(1)
      expect(result[:errors]).to eq(1)
    end

    it 'handles not found PRs' do
      allow(service).to receive(:check_pr_status)
        .with('owner', 'repo', 1)
        .and_raise(StandardError.new('404 Not Found'))

      result = service.update_open_prs

      expect(result[:checked]).to eq(1)
      expect(result[:not_found]).to eq(1)

      # Verify PR was marked as checked
      pr1.reload
      expect(pr1.last_checked_at).not_to be_nil
    end
  end
end
