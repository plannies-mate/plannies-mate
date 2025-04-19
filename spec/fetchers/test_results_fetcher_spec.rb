# frozen_string_literal: true

require_relative '../spec_helper'
require_relative '../../app/fetchers/test_results_fetcher'
require_relative '../../app/fetchers/test_result_details_fetcher'

RSpec.describe TestResultsFetcher do
  describe '#fetch' do
    let(:fetcher) { TestResultsFetcher.new }
    let(:test_var_dir) { File.join(Dir.tmpdir, 'test_results_fetcher_test') }

    before do
      allow(described_class).to receive(:var_dir).and_return(test_var_dir)
      FileUtils.mkdir_p(test_var_dir)
    end

    after do
      FileUtils.rm_rf(test_var_dir)
    end

    it 'fetches test results from morph.io',
       vcr: { cassette_name: cassette_name('test_results/list') } do
      test_results = fetcher.fetch

      expect(test_results).to be_an(Array)
      expect(test_results.size).to be >= 2 # Should have multiple valid test results

      # Each result should have required fields
      test_results.each do |test_result|
        expect(test_result).to include('lang', 'auto_run', 'errored', 'description', 'name',
                                       'running')

        expect(test_result['lang']).to be_a(String)
        expect(test_result['auto_run']).to be_in([true, false])
        expect(test_result['errored']).to be_in([true, false])
        expect(test_result['name']).to be_a(String)
        expect(test_result['running']).to be_in([true, false])
      end

      # Should include a `multiple_*` repo (used in other tests)
      expect(test_results.find { |r| r['name'].start_with? 'multiple_' }).not_to be_nil

      # Should include something that is not `multiple_*` (eg clarence)
      expect(test_results.find { |r| !r['name'].start_with? 'multiple_' }).not_to be_nil

      # Should NOT include selfie-scraper (invalid planner)
      expect(test_results.find { |r| r['name'] == 'selfie-scraper' }).to be_nil
    end

    it 'fetches test result for valid scraper with required fields',
       vcr: { cassette_name: cassette_name('test_results/specific_valid') } do
      test_results = fetcher.fetch

      # Find clarence in results
      custom = test_results.find { |r| !r['name'].start_with? 'multiple_' }
      expect(custom).not_to be_nil
      expect(custom['description']).to be_a(String)
    end

    it 'excludes scrapers without required fields',
       vcr: { cassette_name: cassette_name('test_results/exclude_invalid') } do
      # Force cache invalidation to ensure we check all scrapers
      test_results = fetcher.fetch

      # Selfie scraper should be excluded as it lacks required fields
      selfie = test_results.find { |r| r['name'] == 'selfie-scraper' }
      expect(selfie).to be_nil
    end
  end
end
