# frozen_string_literal: true

# == Schema Information
#
# Table name: pull_requests
#
#  id                    :integer          not null, primary key
#  base_branch_name      :string           not null
#  closed_at             :datetime
#  head_branch_name      :string           not null
#  import_trigger_reason :string
#  import_triggered_at   :datetime
#  locked                :boolean          default(FALSE), not null
#  merge_commit_sha      :string
#  merged_at             :datetime
#  needs_import          :boolean          default(FALSE), not null
#  number                :integer          not null
#  state                 :string           not null
#  title                 :string           not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  issue_id              :integer          not null
#  scraper_id            :integer          not null
#
# Indexes
#
#  index_pull_requests_on_issue_id               (issue_id)
#  index_pull_requests_on_number                 (number) UNIQUE
#  index_pull_requests_on_scraper_id             (scraper_id)
#  index_pull_requests_on_scraper_id_and_number  (scraper_id,number) UNIQUE
#
# Foreign Keys
#
#  issue_id    (issue_id => issues.id)
#  scraper_id  (scraper_id => scrapers.id)
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
        created_at: Date.today,
        github_user_id: 1,
        scraper_id: 1
      )

      duplicate = described_class.new(
        url: 'https://github.com/test/repo/pull/1',
        created_at: Date.today,
        github_user_id: 1,
        scraper_id: 1
      )

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:url]).to include('has already been taken')
    end
  end

  describe 'url parsing methods' do
    it 'extracts GitHub URL components' do
      pr = described_class.new(url: 'https://github.com/planningalerts-scrapers/multiple_masterview/pull/5')

      expect(pr.github_owner).to eq('planningalerts-scrapers')
      expect(pr.github_name).to eq('multiple_masterview')
      expect(pr.pr_number).to eq(5)
    end

    it 'returns nil for attributes of invalid URLs' do
      pr = described_class.new(url: 'https://example.com/not-github')

      expect(pr.github_owner).to be_nil
      expect(pr.github_name).to be_nil
      expect(pr.pr_number).to be_nil
    end
  end

  describe 'scopes' do
    before do
      described_class.destroy_all

      @open_pr = described_class.create!(
        url: 'https://github.com/test/repo/pull/1',
        title: 'Open PR',
        created_at: Date.today,
        github_user_id: 1,
        scraper_id: 1
      )

      @closed_merged_pr = described_class.create!(
        url: 'https://github.com/test/repo/pull/2',
        title: 'Merged PR',
        created_at: Date.today - 10,
        closed_at_date: Date.today - 5,
        merged: true,
        github_user_id: 1,
        scraper_id: 1
      )

      @closed_rejected_pr = described_class.create!(
        url: 'https://github.com/test/repo/pull/3',
        title: 'Rejected PR',
        created_at: Date.today - 15,
        closed_at_date: Date.today - 8,
        merged: false,
        github_user_id: 1,
        scraper_id: 1
      )
    end

    it 'filters open PRs' do
      open_prs = described_class.open
      expect(open_prs).to include(@open_pr)
      expect(open_prs).not_to include(@closed_merged_pr)
      expect(open_prs).not_to include(@closed_rejected_pr)
    end

    it 'filters closed PRs' do
      closed_prs = described_class.closed
      expect(closed_prs).not_to include(@open_pr)
      expect(closed_prs).to include(@closed_merged_pr)
      expect(closed_prs).to include(@closed_rejected_pr)
    end

    it 'filters merged PRs' do
      merged_prs = described_class.merged
      expect(merged_prs).not_to include(@open_pr)
      expect(merged_prs).to include(@closed_merged_pr)
      expect(merged_prs).not_to include(@closed_rejected_pr)
    end

    it 'filters rejected PRs' do
      rejected_prs = described_class.rejected
      expect(rejected_prs).not_to include(@open_pr)
      expect(rejected_prs).not_to include(@closed_merged_pr)
      expect(rejected_prs).to include(@closed_rejected_pr)
    end
  end
end
