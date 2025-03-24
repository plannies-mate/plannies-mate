# frozen_string_literal: true

# == Schema Information
#
# Table name: pull_requests
#
#  id                  :integer          not null, primary key
#  accepted            :boolean          default(FALSE)
#  closed_at_date      :date
#  github_owner        :string
#  github_repo         :string
#  last_checked_at     :datetime
#  needs_github_update :boolean          default(TRUE)
#  pr_number           :integer
#  title               :string
#  url                 :string           not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  scraper_id          :integer
#
# Indexes
#
#  index_pull_requests_on_scraper_id  (scraper_id)
#  index_pull_requests_on_url         (url) UNIQUE
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

  describe '#parse_github_url' do
    it 'parses GitHub URL components' do
      pr = described_class.new(url: 'https://github.com/owner/repo-name/pull/123')
      pr.parse_github_url

      expect(pr.github_owner).to eq('owner')
      expect(pr.github_repo).to eq('repo-name')
      expect(pr.pr_number).to eq(123)
    end

    it 'returns false for invalid URLs' do
      pr = described_class.new(url: 'https://example.com/not-github')
      result = pr.parse_github_url

      expect(result).to be false
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

  describe '.import_from_file' do
    let(:brimbank) { Fixture.find(Authority, :brimbank) }
    let(:bunbury) { Fixture.find(Authority, :bunbury) }

    before do
      # Setup PrFileService mock
      allow(PrFileService).to receive(:read_file).and_return([
                                                               {
                                                                 'title' => 'Fix Brimbank',
                                                                 'url' => 'https://github.com/test/repo/pull/1',
                                                                 'created_at' => '2025-03-20',
                                                                 'authorities' => ['brimbank'],
                                                               },
                                                               {
                                                                 'title' => 'Fix Bunbury',
                                                                 'url' => 'https://github.com/test/repo/pull/2',
                                                                 'created_at' => '2025-03-21',
                                                                 'closed_at' => '2025-03-24',
                                                                 'accepted' => true,
                                                                 'authorities' => ['bunbury'],
                                                               },
                                                             ])
    end

    it 'imports new PRs from YAML data' do
      expect do
        result = described_class.import_from_file
        expect(result[:imported]).to eq(2)
      end.to change(described_class, :count).by(2)

      # Check associations
      pr1 = described_class.find_by(url: 'https://github.com/test/repo/pull/1')
      expect(pr1.authorities.count).to eq(1)
      expect(pr1.authorities.first.short_name).to eq('brimbank')
      expect(pr1.needs_github_update).to be true

      pr2 = described_class.find_by(url: 'https://github.com/test/repo/pull/2')
      expect(pr2.authorities.count).to eq(1)
      expect(pr2.authorities.first.short_name).to eq('bunbury')
      expect(pr2.needs_github_update).to be false
      expect(pr2.closed_at_date).to eq(Date.parse('2025-03-24'))
      expect(pr2.accepted).to be true
    end

    it 'supports both authorities and affected_authorities fields' do
      # Use affected_authorities instead
      allow(PrFileService).to receive(:read_file).and_return([
                                                               {
                                                                 'title' => 'Fix Brimbank',
                                                                 'url' => 'https://github.com/test/repo/pull/1',
                                                                 'created_at' => '2025-03-20',
                                                                 'affected_authorities' => ['brimbank'],
                                                               },
                                                             ])

      result = described_class.import_from_file
      expect(result[:imported]).to eq(1)

      pr = described_class.find_by(url: 'https://github.com/test/repo/pull/1')
      expect(pr.authorities.count).to eq(1)
      expect(pr.authorities.first.short_name).to eq('brimbank')
    end

    it 'updates existing PRs' do
      # Create existing PR
      pr = described_class.create!(
        url: 'https://github.com/test/repo/pull/1',
        title: 'Old Title',
        created_at: Date.today
      )

      # Mock read_file with updated data
      allow(PrFileService).to receive(:read_file).and_return([
                                                               {
                                                                 'title' => 'New Title',
                                                                 'url' => 'https://github.com/test/repo/pull/1',
                                                                 'created_at' => Date.today.to_s,
                                                                 'closed_at' => Date.today.to_s,
                                                                 'accepted' => true,
                                                                 'authorities' => ['brimbank'],
                                                               },
                                                             ])

      result = described_class.import_from_file
      expect(result[:updated]).to eq(1)

      pr.reload
      expect(pr.title).to eq('New Title')
      expect(pr.closed_at_date).to eq(Date.today)
      expect(pr.accepted).to be true
      expect(pr.authorities.count).to eq(1)
    end

    it 'returns empty result for invalid YAML' do
      allow(PrFileService).to receive(:read_file).and_return('not an array')

      result = described_class.import_from_file
      expect(result[:imported]).to eq(0)
      expect(result[:updated]).to eq(0)
    end
  end
end
