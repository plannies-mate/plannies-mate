# frozen_string_literal: true

# == Schema Information
#
# Table name: issues
#
#  id                  :integer          not null, primary key
#  closed_at           :datetime
#  locked              :boolean          default(FALSE), not null
#  needs_generate      :boolean          default(TRUE), not null
#  needs_import        :boolean          default(TRUE), not null
#  number              :integer          not null
#  title               :string           not null
#  update_reason       :string
#  update_requested_at :datetime
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  authority_id        :integer
#  scraper_id          :integer
#
# Indexes
#
#  index_issues_on_authority_id  (authority_id)
#  index_issues_on_number        (number) UNIQUE
#  index_issues_on_scraper_id    (scraper_id)
#
# Foreign Keys
#
#  authority_id  (authority_id => authorities.id)
#  scraper_id    (scraper_id => scrapers.id)
#
require_relative '../spec_helper'
require_relative '../../app/models/issue'

RSpec.describe Issue do
  describe 'fixtures' do
    it 'loads issues from fixtures' do
      expect(Issue.count).to be > 0
    end

    it 'loads issue correctly' do
      issue = FixtureHelper.find(Issue, :issue_1)

      expect(issue).not_to be_nil
      expect(issue.number).to eq(1)
      expect(issue.title).to eq('Burdekin Shire Council')
      expect(issue.scraper.name).to eq('BurdekinShire_DAs')
    end
  end

  describe 'validations' do
    it 'requires number' do
      issue = Issue.new(title: 'Test Issue', scraper: Scraper.first)
      expect(issue).not_to be_valid
      expect(issue.errors[:number]).to include("can't be blank")
    end

    it 'requires title' do
      issue = Issue.new(number: 123, scraper: Scraper.first)
      expect(issue).not_to be_valid
      expect(issue.errors[:title]).to include("can't be blank")
    end

    it 'requires uniqueness of number' do
      existing = FixtureHelper.find(Issue, :issue_1)

      duplicate = Issue.new(
        number: existing.number,
        title: 'Another Issue',
        scraper: Scraper.first
      )

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:number]).to include('has already been taken')
    end
  end

  describe 'associations' do
    it 'belongs to a scraper' do
      issue = FixtureHelper.find(Issue, :issue_1)
      expect(issue.scraper).to be_a(Scraper)
    end

    it 'can belong to an authority' do
      issue = FixtureHelper.find(Issue, :issue_1)
      expect(issue.authority).to be_a(Authority)
    end

    it 'has assignees' do
      issue = FixtureHelper.find(Issue, :issue_1)
      expect(issue.assignees).to be_an(ActiveRecord::Relation)
    end

    it 'has labels' do
      issue = FixtureHelper.find(Issue, :issue_2)
      expect(issue.labels).to be_an(ActiveRecord::Relation)
    end
  end

  describe 'scopes' do
    it 'has open scope' do
      open_issues = Issue.open.map(&:title)
      expect(open_issues).not_to include(FixtureHelper.find(Issue, :issue_1).title)
      expect(open_issues).to include(FixtureHelper.find(Issue, :issue_2).title)
    end

    it 'has closed scope' do
      # Create a closed issue
      closed_issue = Issue.create!(
        number: 999,
        title: 'Closed Issue',
        scraper: Scraper.first,
        closed_at: Time.now
      )

      expect(Issue.closed).to include(closed_issue)
      closed_issue.destroy # Clean up
    end
  end

  describe '#open?' do
    it 'returns true when closed_at is nil' do
      issue = FixtureHelper.find(Issue, :issue_1)
      issue.closed_at = nil
      expect(issue.open?).to be true
    end

    it 'returns false when closed_at is present' do
      issue = FixtureHelper.find(Issue, :issue_1)
      issue.closed_at = Time.now
      expect(issue.open?).to be false
    end
  end

  describe '#to_param' do
    it 'returns number as string' do
      issue = FixtureHelper.find(Issue, :issue_1)
      expect(issue.to_param).to eq('1')
    end
  end
end
