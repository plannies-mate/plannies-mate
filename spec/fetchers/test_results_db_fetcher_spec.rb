# frozen_string_literal: true

require_relative '../spec_helper'
require_relative '../../app/fetchers/test_results_db_fetcher'

RSpec.describe TestResultsDbFetcher do
  let(:fetcher) { described_class.new }

  describe '#fetch_authority_label_count' do
    context 'With a multiple_* scraper', vcr: { cassette_name: cassette_name('fetch_authority_label_count') } do
      let(:test_name) do
        index_fetcher = TestResultsFetcher.new
        details_fetcher = TestResultDetailsFetcher.new
        list = index_fetcher.fetch
        result = list&.find do |item|
          item['full_name']&.start_with?('multiple_') &&
            (details = details_fetcher.fetch(item['full_name'])) &&
            details['tables']&.include?('scrape_summary')
        end&.dig('full_name')
        puts "Using test_name: #{result}"
        result
      end

      it 'fetches data from the API' do
        results = fetcher.fetch_authority_label_count(test_name)

        expect(results).to be_an(Hash)
        expect(results.size).to be >= 3

        results.each do |authority_label, count|
          expect(authority_label).to be_a(String)
          expect(count).to be_a(Integer)
          expect(count).to be_positive
        end
      end
    end

    context 'With a empty name' do
      it 'requires a test name' do
        expect { fetcher.fetch_authority_label_count('') }.to raise_error(ArgumentError)
      end
    end

    context 'with a scraper that does not have scrape_summary',
            vcr: { cassette_name: cassette_name('fetch_authority_label_count_bad') } do
      let(:test_name) do
        index_fetcher = TestResultsFetcher.new
        list = index_fetcher.fetch
        result = list&.find do |item|
          !item['full_name']&.start_with?('multiple_')
        end&.dig('full_name')
        puts "Using test_name: #{result}"
        result
      end

      it 'throws an exception' do
        expect { fetcher.fetch_authority_label_count(test_name) }.to raise_error(Mechanize::ResponseCodeError)
      end
    end
  end

  describe '#fetch_count' do
    context 'with valid name', vcr: { cassette_name: cassette_name('fetch_count-custom') } do
      let(:test_name) do
        index_fetcher = TestResultsFetcher.new
        list = index_fetcher.fetch
        list&.find do |item|
          !item['full_name']&.start_with?('multiple_')
        end&.dig('full_name')
      end

      it 'returns a count' do
        result = fetcher.fetch_count(test_name)

        expect(result).to be_a(Integer)
        expect(result).to be_positive
      end
    end

    context 'with blank name' do
      it 'requires a test name' do
        expect { fetcher.fetch_authority_label_count('') }.to raise_error(ArgumentError)
      end
    end
  end
end
