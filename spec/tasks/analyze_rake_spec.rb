# frozen_string_literal: true

require_relative '../spec_helper'
require 'rake'

RSpec.describe 'analyze rake tasks' do
  before do
    Rake::Task.tasks.each(&:reenable)
    Rake::Task.load_tasks if Rake::Task.tasks.empty?
  end

  after do
    # Clean up
    RSpec::Mocks.space.reset_all
  end

  describe 'analyze:broken_scores' do
    before do
      # Reset broken scores to ensure clean test state
      Authority.update_all(broken_score: nil)
      Scraper.update_all(broken_score: nil)
    end

    it 'correctly assigns broken scores to authorities and scrapers' do
      # Execute the rake task
      Rake::Task['analyze:broken_scores'].invoke

      # Check that non-broken authorities have zero scores
      working_authorities = Authority.where(possibly_broken: false)
      expect(working_authorities.count).to be > 0
      expect(working_authorities.pluck(:broken_score).uniq).to eq([0])

      # Check that broken authorities have scores assigned
      broken_authorities = Authority.where(possibly_broken: true)
      expect(broken_authorities.count).to be > 0
      expect(broken_authorities.where('broken_score > 0').count).to eq(broken_authorities.count)

      # Check that scrapers with broken authorities have scores assigned
      scrapers_with_broken = Scraper.joins(:authorities).where(authorities: { possibly_broken: true }).distinct
      expect(scrapers_with_broken.count).to be > 0
      expect(scrapers_with_broken.where('scrapers.broken_score > 0').count).to eq(scrapers_with_broken.count)

      # Check that other scrapers have zero scores
      other_scrapers = Scraper.where.not(id: scrapers_with_broken.pluck(:id))
      expect(other_scrapers.pluck(:broken_score).uniq).to eq([0]) if other_scrapers.count > 0

      # Verify specific test cases from fixtures
      bathurst = Authority.find_by(short_name: 'bathurst')
      expect(bathurst.broken_score).to be > 0

      multiple_atdis = Scraper.find_by(name: 'multiple_atdis')
      expect(multiple_atdis.broken_score).to be > 0
    end
  end
end
