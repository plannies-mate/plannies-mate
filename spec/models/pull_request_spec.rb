# frozen_string_literal: true

# == Schema Information
#
# Table name: pull_requests
#
#  id               :integer          not null, primary key
#  base_branch_name :string           not null
#  closed_at        :datetime
#  head_branch_name :string           not null
#  locked           :boolean          default(FALSE), not null
#  merged_at        :datetime
#  number           :integer          not null
#  title            :string           not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  issue_id         :integer
#  scraper_id       :integer          not null
#
# Indexes
#
#  index_pull_requests_on_issue_id               (issue_id)
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
    it 'requires number' do
      pr = described_class.new(created_at: Date.today)
      expect(pr).not_to be_valid
      expect(pr.errors[:number]).to include("can't be blank")
    end

    it 'requires unique number' do
      record = described_class.first

      duplicate = described_class.new(
        number: record.number,
        created_at: Date.today,
        scraper: record.scraper
      )

      puts duplicate.errors.inspect
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:number]).to include('has already been taken')
    end
  end

  # FIXME: Use fixtures not created records
  # describe 'scopes' do
  #   before do
  #     described_class.destroy_all
  #
  #     @open_pr = described_class.create!(
  #       number: 1,
  #       title: 'Open PR',
  #       created_at: Date.today,
  #       user_id: 1,
  #       scraper_id: 1,
  #       issue: Issue.first
  #     )
  #
  #     @closed_merged_pr = described_class.create!(
  #       number: '2',
  #       title: 'Merged PR',
  #       created_at: Date.today - 10,
  #       closed_at_date: Date.today - 5,
  #       merged: true,
  #       user_id: 1,
  #       scraper_id: 1,
  #       issue_id: 1
  #     )
  #
  #     @closed_rejected_pr = described_class.create!(
  #       number: '3',
  #       title: 'Rejected PR',
  #       created_at: Date.today - 15,
  #       closed_at_date: Date.today - 8,
  #       merged: false,
  #       user_id: 1,
  #       scraper_id: 1,
  #       issue_id: 1
  #     )
  #   end
  #
  #   it 'filters open PRs' do
  #     open_prs = described_class.open
  #     expect(open_prs).to include(@open_pr)
  #     expect(open_prs).not_to include(@closed_merged_pr)
  #     expect(open_prs).not_to include(@closed_rejected_pr)
  #   end
  #
  #   it 'filters closed PRs' do
  #     closed_prs = described_class.closed
  #     expect(closed_prs).not_to include(@open_pr)
  #     expect(closed_prs).to include(@closed_merged_pr)
  #     expect(closed_prs).to include(@closed_rejected_pr)
  #   end
  #
  #   it 'filters merged PRs' do
  #     merged_prs = described_class.merged
  #     expect(merged_prs).not_to include(@open_pr)
  #     expect(merged_prs).to include(@closed_merged_pr)
  #     expect(merged_prs).not_to include(@closed_rejected_pr)
  #   end
  #
  #   it 'filters rejected PRs' do
  #     rejected_prs = described_class.rejected
  #     expect(rejected_prs).not_to include(@open_pr)
  #     expect(rejected_prs).not_to include(@closed_merged_pr)
  #     expect(rejected_prs).to include(@closed_rejected_pr)
  #   end
  # end
end
