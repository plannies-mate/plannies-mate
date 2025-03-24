# frozen_string_literal: true

require 'spec_helper'
require_relative '../../app/services/pr_sync_service'

RSpec.describe PrSyncService do
  let(:temp_file) { Tempfile.new(['pull_requests', '.yml']) }
  let(:service) { described_class.new(temp_file.path) }

  after do
    temp_file.close
    temp_file.unlink
  end

  describe '#sync_from_yaml' do
    it 'returns error when file does not exist' do
      non_existent_file = '/tmp/this_file_does_not_exist.yml'
      service = described_class.new(non_existent_file)

      result = service.sync_from_yaml

      expect(result[:error]).to include('not found')
    end

    it 'returns error for invalid YAML' do
      temp_file.write('this is not: valid: yaml')
      temp_file.flush

      result = service.sync_from_yaml

      expect(result[:error]).to include('Failed to parse YAML')
    end

    it 'syncs PRs from valid YAML' do
      yaml_data = [
        {
          'title' => 'Test PR',
          'url' => 'https://github.com/test/repo/pull/1',
          'created_at' => '2025-03-24',
          'authorities' => [],
        },
      ]

      temp_file.write(YAML.dump(yaml_data))
      temp_file.flush

      # Mock PullRequest.import_from_file to avoid actual DB operations
      expect(PullRequest).to receive(:import_from_file)
        .with(yaml_data)
        .and_return({ imported: 1, updated: 0 })

      result = service.sync_from_yaml

      expect(result[:success]).to be true
      expect(result[:imported]).to eq(1)
    end
  end

  describe '#sync_to_yaml' do
    it 'exports PRs to YAML file' do
      yaml_data = [
        {
          'title' => 'Test PR',
          'url' => 'https://github.com/test/repo/pull/1',
          'created_at' => '2025-03-24',
          'authorities' => [],
        },
      ]

      # Mock the private export_prs_to_yaml method
      expect(service).to receive(:export_prs_to_yaml).and_return(yaml_data)

      result = service.sync_to_yaml

      expect(result[:success]).to be true
      expect(result[:exported]).to eq(1)

      # Check file was written
      temp_file.rewind
      written_data = YAML.load(temp_file.read)
      expect(written_data).to eq(yaml_data)
    end
  end

  describe '#update_from_github' do
    let(:github_service) { instance_double(GithubPrService) }
    let(:pr1) do
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

    before do
      allow(GithubPrService).to receive(:new).and_return(github_service)
      allow(service).to receive(:sync_to_yaml).and_return({ success: true, exported: 1 })
    end

    after do
      pr1.destroy if pr1.persisted?
    end

    it 'updates PR status from GitHub' do
      github_data = {
        'state' => 'closed',
        'closed_at' => '2025-03-24T12:00:00Z',
        'merged' => true,
      }

      expect(github_service).to receive(:check_pr_status)
        .with('owner', 'repo', 1)
        .and_return(github_data)

      expect(pr1).to receive(:update_from_github)
        .with(github_data)
        .and_return(true)

      result = service.update_from_github

      expect(result[:updated]).to eq(1)
    end

    it 'handles GitHub API errors' do
      expect(github_service).to receive(:check_pr_status)
        .with('owner', 'repo', 1)
        .and_raise(StandardError.new('API error'))

      result = service.update_from_github

      expect(result[:errors]).to eq(1)
    end

    it 'handles not found PRs' do
      expect(github_service).to receive(:check_pr_status)
        .with('owner', 'repo', 1)
        .and_raise(StandardError.new('404 Not Found'))

      expect(pr1).to receive(:update).with(hash_including(:last_checked_at))

      result = service.update_from_github

      expect(result[:not_found]).to eq(1)
    end
  end
end
