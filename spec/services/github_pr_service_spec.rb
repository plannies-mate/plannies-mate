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
end
