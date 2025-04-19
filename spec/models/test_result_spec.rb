# frozen_string_literal: true

# == Schema Information
#
# Table name: test_results
#
#  id         :integer          not null, primary key
#  commit_sha :string           not null
#  duration   :integer
#  failed     :boolean          default(FALSE), not null
#  name       :string           not null
#  run_at     :datetime         not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  scraper_id :integer          not null
#
# Indexes
#
#  index_test_results_on_git_sha          ("git_sha")
#  index_test_results_on_name_and_run_at  (name,run_at) UNIQUE
#  index_test_results_on_scraper_id       (scraper_id)
#
# Foreign Keys
#
#  scraper_id  (scraper_id => scrapers.id)
#
require_relative '../spec_helper'
require_relative '../../app/models/test_result'

RSpec.describe TestResult do
  describe 'associations' do
    it 'belongs to a scraper' do
      test_result = described_class.new
      expect(test_result).to respond_to(:scraper)
    end

    it 'has many authority test results' do
      test_result = described_class.new
      expect(test_result).to respond_to(:authority_test_results)
    end

    it 'has many authorities through authority test results' do
      test_result = described_class.new
      expect(test_result).to respond_to(:authorities)
    end
  end

  describe 'validations' do
    it 'requires name, git_sha, and run_at' do
      test_result = described_class.new
      expect(test_result).not_to be_valid
      expect(test_result.errors[:name]).to include("can't be blank")
      expect(test_result.errors[:commit_sha]).to include("can't be blank")
      expect(test_result.errors[:run_at]).to include("can't be blank")
    end

    it 'requires unique run_at for the same name' do
      existing = FixtureHelper.find(described_class, :test_multiple_atdis_success)
      duplicate = described_class.new(
        name: existing.name,
        commit_sha: 'different_sha',
        run_at: existing.run_at,
        scraper: existing.scraper
      )

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:run_at]).to include('has already been taken')
    end
  end

  describe 'scopes' do
    before do
      @passed = FixtureHelper.find(described_class, :test_multiple_atdis_success)
      @failed = FixtureHelper.find(described_class, :test_multiple_atdis_fail)
    end

    it 'filters passed tests' do
      results = described_class.passed
      expect(results).to include(@passed)
      expect(results).not_to include(@failed)
    end

    it 'filters failed tests' do
      results = described_class.failed
      expect(results).not_to include(@passed)
      expect(results).to include(@failed)
    end

    it 'orders recent tests by run_at descending' do
      results = described_class.recent.to_a
      expect(results.first.run_at).to be > results.last.run_at
    end
  end

  describe '#matching_pull_requests' do
    it 'finds pull requests with matching head_sha' do
      test_result = FixtureHelper.find(described_class, :test_multiple_atdis_success)
      matching_pr = FixtureHelper.find(PullRequest, :pr18)

      expect(test_result.pull_requests).to include(matching_pr)
    end
  end

  describe '#html_url' do
    it 'returns the correct morph.io URL' do
      test_result = described_class.new(name: 'some-repo')
      expect(test_result.html_url).to eq('https://morph.io/ianheggie-oaf/some-repo')
    end
  end
end
