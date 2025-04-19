# frozen_string_literal: true

require 'time'
require_relative '../spec_helper'
require_relative '../../app/importers/test_results_importer'

RSpec.describe TestResultsImporter do
  before do
    @importer = described_class.new
  end

  context 'importing from scratch' do
    before do
      FixtureHelper.clear_database
    end

    it 'imports test_results', vcr: { cassette_name: cassette_name('import_test_results_from_scratch') } do
      @importer.import

      test_result_count = TestResult.count
      expect(test_result_count).to be > 2
    end
  end

  # it 'imports test_results and scrapers, adding whats missing, updating what has changed',
  #    vcr: { cassette_name: cassette_name('import_test_results_from_scratch_then_redo') } do
  #   @importer.import
  #
  #   test_result_count = TestResult.count
  #   expect(test_result_count).to be > 100
  #
  #   scraper_count = Scraper.count
  #   expect(scraper_count).to be_between(30, 50)
  #
  #   destroyed_scraper = Scraper.first
  #   puts "Destroying scraper #{destroyed_scraper.name} and associated test_results: #{destroyed_scraper.test_results.pluck(:short_name).inspect}"
  #   destroyed_test_results = destroyed_scraper.test_results.destroy_all
  #   destroyed_scraper.destroy
  #
  #   updated_scraper = Scraper.last
  #   updated_scraper_name = updated_scraper.name
  #   puts "Changing scraper name: #{updated_scraper_name} to BadName"
  #   updated_scraper.update! name: 'BadName'
  #
  #   updated_test_result = updated_scraper.test_results.last
  #   updated_test_result_name = updated_test_result.name
  #   puts "Changing test_result name: #{updated_test_result_name} to BadName"
  #   updated_test_result.update! name: 'BadName'
  #
  #   latest_update = [TestResult.maximum(:updated_at), Scraper.maximum(:updated_at)].compact.max
  #   sleep(0.1) while Time.now.to_i <= latest_update.to_i
  #
  #   # puts 'TestResults:'
  #   # TestResult.order(:short_name).each do |test_result|
  #   #   puts "#{test_result.short_name} #{test_result.name}#{test_result.delisted_on ? ' DELISTED' : ''}"
  #   # end
  #   # puts "Scraper: #{Scraper.pluck(:name).sort.to_yaml}"
  #
  #   puts '-' * 50, 'NON FORCED IMPORT'
  #   # Expect pages to all be the same
  #   @importer.import
  #
  #   # puts "Scraper: #{Scraper.pluck(:name).sort.to_yaml}"
  #
  #   expect(TestResult.count).to eq(test_result_count - 1)
  #   expect(Scraper.count).to eq(scraper_count - 1)
  #
  #   scraper_names = Scraper.pluck(:name)
  #   test_result_names = TestResult.pluck(:name)
  #   expect(destroyed_scraper.name).not_to be_in(scraper_names)
  #   expect(destroyed_test_results.first.name).not_to be_in(test_result_names)
  #   expect(updated_scraper_name).not_to be_in(scraper_names)
  #   expect(updated_test_result_name).not_to be_in(test_result_names)
  #   expect('BadName').to be_in(scraper_names)
  #   expect('BadName').to be_in(test_result_names)
  #
  #   puts '-' * 50, 'FORCING IMPORT'
  #   # Everything should be updated when last checked 8 days ago
  #   HttpCacheEntry.where.not(last_success_at: nil).update_all(last_success_at: 8.days.ago)
  #   @importer.import
  #
  #   # puts "Scraper: #{Scraper.pluck(:name).sort.to_yaml}"
  #
  #   expect(TestResult.count).to eq(test_result_count)
  #   # BadName is not deleted
  #   expect(Scraper.count).to eq(scraper_count + 1)
  #
  #   scraper_names = Scraper.pluck(:name)
  #   test_result_names = TestResult.pluck(:name)
  #   expect(destroyed_scraper.name).to be_in(scraper_names)
  #   expect(destroyed_test_results.first.name).to be_in(test_result_names)
  #   expect(updated_scraper_name).to be_in(scraper_names)
  #   expect(updated_test_result_name).to be_in(test_result_names)
  #   expect('BadName').to be_in(scraper_names)
  #   expect('BadName').not_to be_in(test_result_names)
  # end
end
