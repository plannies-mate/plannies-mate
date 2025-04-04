# frozen_string_literal: true

# == Schema Information
#
# Table name: branches
#
#  id              :integer          not null, primary key
#  name            :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  pull_request_id :integer
#  scraper_id      :integer          not null
#
# Indexes
#
#  idx_scraper_branches               (scraper_id,name) UNIQUE
#  index_branches_on_pull_request_id  (pull_request_id)
#  index_branches_on_scraper_id       (scraper_id)
#
# Foreign Keys
#
#  pull_request_id  (pull_request_id => pull_requests.id)
#  scraper_id       (scraper_id => scrapers.id)
#
require_relative '../spec_helper'
require_relative '../../app/models/branch'

RSpec.describe Branch do
  describe 'fixtures' do
    it 'loads branches from fixtures' do
      expect(Branch.count).to be > 0
    end

    it 'loads feature branch correctly' do
      branch = FixtureHelper.find(Branch, :feature_branch)
      
      expect(branch).not_to be_nil
      expect(branch.name).to eq('feature/fix-broken-authorities')
      expect(branch.scraper.name).to eq('multiple_atdis')
      expect(branch.pull_request).not_to be_nil
    end
  end

  describe 'validations' do
    it 'requires name' do
      branch = Branch.new(scraper: Scraper.first)
      expect(branch).not_to be_valid
      expect(branch.errors[:name]).to include("can't be blank")
    end

    it 'requires uniqueness of name scoped to scraper' do
      existing = FixtureHelper.find(Branch, :feature_branch)
      
      duplicate = Branch.new(
        name: existing.name,
        scraper: existing.scraper
      )
      
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:name]).to include('has already been taken')
      
      # Different scraper should allow same name
      different_scraper = Scraper.where.not(id: existing.scraper_id).first
      non_duplicate = Branch.new(
        name: existing.name,
        scraper: different_scraper
      )
      
      expect(non_duplicate.errors[:name]).not_to include('has already been taken')
    end
  end

  describe 'associations' do
    it 'belongs to a scraper' do
      branch = FixtureHelper.find(Branch, :feature_branch)
      expect(branch.scraper).to be_a(Scraper)
    end

    it 'can belong to a pull request' do
      branch = FixtureHelper.find(Branch, :feature_branch)
      expect(branch.pull_request).to be_a(PullRequest)
    end
  end
end
