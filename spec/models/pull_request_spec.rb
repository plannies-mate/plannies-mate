# frozen_string_literal: true

# == Schema Information
#
# Table name: pull_requests
#
#  id                  :integer          not null, primary key
#  closed_at_date      :date
#  last_checked_at     :datetime
#  merged              :boolean          default(FALSE)
#  needs_github_update :boolean          default(TRUE)
#  title               :string
#  url                 :string           not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  github_user_id      :integer
#  scraper_id          :integer
#
# Indexes
#
#  index_pull_requests_on_github_user_id  (github_user_id)
#  index_pull_requests_on_scraper_id      (scraper_id)
#  index_pull_requests_on_url             (url) UNIQUE
#
require 'spec_helper'
require_relative '../../app/models/pull_request'

RSpec.describe PullRequest do
  describe 'validations' do
    it 'requires url' do
      pr = described_class.new(created_at: Date.today)
      expect(pr).not_to be_valid
      expect(pr.errors[:url]).to include("can't be blank")
    end

    it 'requires created_at' do
      pr = described_class.new(url: 'https://github.com/test/repo/pull/1')
      expect(pr).not_to be_valid
      expect(pr.errors[:created_at]).to include("can't be blank")
    end

    it 'requires unique url' do
      described_class.create!(
        url: 'https://github.com/test/repo/pull/1',
        created_at: Date.today
      )

      duplicate = described_class.new(
        url: 'https://github.com/test/repo/pull/1',
        created_at: Date.today
      )

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:url]).to include('has already been taken')
    end
  end

  describe 'github_url helpers' do
    it 'parses GitHub URL components' do
      pr = described_class.new(url: 'https://github.com/owner/repo-name/pull/123')

      expect(pr.github_owner).to eq('owner')
      expect(pr.github_repo).to eq('repo-name')
      expect(pr.pr_number).to eq(123)
    end

    it 'returns nil for attributes of invalid URLs' do
      pr = described_class.new(url: 'https://example.com/not-github')

      expect(pr.github_owner).to be_nil
      expect(pr.github_repo).to be_nil
      expect(pr.pr_number).to be_nil
    end
  end

  describe '#update_from_github' do
    let(:pr) do
      described_class.create!(
        url: 'https://github.com/test/repo/pull/1',
        created_at: Date.today,
        needs_github_update: true
      )
    end

    it 'updates closed PR status' do
      github_data = {
        'state' => 'closed',
        'closed_at' => '2025-03-24T12:00:00Z',
        'merged' => true,
      }

      pr.update_from_github(github_data)

      expect(pr.closed_at_date).to eq(Date.parse('2025-03-24'))
      expect(pr.accepted).to be true
      expect(pr.needs_github_update).to be false
      expect(pr.last_checked_at).not_to be_nil
    end

    it 'does not close an open PR' do
      github_data = {
        'state' => 'open',
        'merged' => false,
      }

      pr.update_from_github(github_data)

      expect(pr.closed_at_date).to be_nil
      expect(pr.accepted).to be false
      expect(pr.needs_github_update).to be true
      expect(pr.last_checked_at).not_to be_nil
    end
  end
end
