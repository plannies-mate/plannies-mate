# frozen_string_literal: true

require_relative '../spec_helper'
require_relative '../../app/fetchers/authorities_fetcher'

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

    it 'fetches test results from https://morph.io/ianheggie-oaf/',
       vcr: { cassette_name: cassette_name('test_results_list') } do
      test_results = fetcher.fetch

      expect(test_results).to be_an(Array)
      expect(test_results.size).to be > 2 # Should have many test_results

      test_results.each do |test_result|
        expect(test_result).to include('lang', 'auto_run', 'errored', 'description', 'full_name', 'running')

        expect(test_result['lang']).to be_a(String)
        expect(test_result['auto_run']).to be_in([true, false])
        expect(test_result['errored']).to be_in([true, false])
        expect(test_result['description']).to be_a(String)
        expect(test_result['full_name']).to be_a(String)
        expect(test_result['running']).to be_in([true, false])
      end
    end

    it 'fetches test result for selfie scraper from https://morph.io/ianheggie-oaf/',
       vcr: { cassette_name: cassette_name('list_includes_selfie') } do
      test_results = fetcher.fetch

      expect(test_results).to be_an(Array)

      selfie_record = test_results.find { |r| r['full_name'] == 'selfie-scraper' }
      expected = {
        'lang' => 'Ruby',
        'auto_run' => true,
        'errored' => false,
        'description' => 'Taking a gander at itself to see if it knows its own github repo / morph scraper name',
        'full_name' => 'selfie-scraper',
        'running' => false,
      }
      expect(selfie_record).to eq(expected)
    end
  end
end
