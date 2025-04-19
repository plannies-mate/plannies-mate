# frozen_string_literal: true

require_relative '../spec_helper'
require_relative '../../app/fetchers/test_result_details_fetcher'

RSpec.describe TestResultDetailsFetcher do
  describe '#fetch' do
    let(:fetcher) { described_class.new }

    context 'with a multiple scraper using scraper_utils gem',
            vcr: { cassette_name: cassette_name('test_result_details/multiple_something') } do
      let(:test_name) do
        index_fetcher = TestResultsFetcher.new
        list = index_fetcher.fetch
        result = list&.find { |item| item['name']&.start_with?('multiple_') }&.dig('name')
        puts "Using test_name: #{result}"
        result
      end

      it 'fetches detailed information' do
        expect(test_name).not_to be_nil

        details = fetcher.fetch(test_name)
        expect(details).to be_a(Hash)

        # Check basic details
        expect(details).to include('failed',
                                   'failed_authorities',
                                   'has_authority_label',
                                   'interrupted_authorities',
                                   'commit_sha',
                                   'run_at',
                                   'run_time',
                                   'successful_authorities',
                                   'tables')

        expect(details['failed']).to be_in([true, false])

        # Check for tables
        expect(details['tables']).to include('data')
        # expect(details['tables']).to include('scrape_log')
        # expect(details['tables']).to include('scrape_summary')

        # Check for authority_label and required fields
        expect(details['has_authority_label']).to be true

        if details['tables'].include?('scrape_summary')
          expect(details).to include('successful_authorities', 'failed_authorities')
          expect(details['successful_authorities']).to be_an(Array)
          expect(details['failed_authorities']).to be_an(Array)
        end
      end
    end

    context 'with a single authority scraper', vcr: { cassette_name: cassette_name('test_result_details/custom') } do
      let(:test_name) do
        index_fetcher = TestResultsFetcher.new
        list = index_fetcher.fetch
        result = list&.find { |item| !item['name']&.start_with?('multiple_') }&.dig('name')
        puts "Using test_name: #{result}"
        result
      end

      it 'fetches detailed information' do
        details = fetcher.fetch(test_name)
        expect(details).to be_a(Hash)

        expect(details).to include('failed', 'has_authority_label', 'commit_sha', 'run_at', 'run_time',
                                   'tables')

        expect(details['tables']).to include('data')
        expect(details['tables']).not_to include('scrape_summary')
        expect(details['has_authority_label']).to be false
        expect(details).not_to include('successful_authorities', 'failed_authorities', 'ignored_authorities')
      end
    end

    context 'with an invalid scraper', vcr: { cassette_name: cassette_name('test_result_details/selfie') } do
      let(:test_name) { 'ianheggie-oaf/selfie-scraper' }

      it 'indicates missing required fields' do
        expect { fetcher.fetch(test_name) }
          .to raise_error('Missing required fields: council_reference, address, description, info_url, date_scraped for https://morph.io/ianheggie-oaf/selfie-scraper')
      end
    end

    it 'requires a test name' do
      expect { fetcher.fetch('') }.to raise_error(ArgumentError)
    end
  end
end
