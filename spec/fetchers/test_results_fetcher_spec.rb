# frozen_string_literal: true

require_relative '../spec_helper'
require_relative '../../app/fetchers/authorities_fetcher'

RSpec.describe TestResultsFetcher do
  describe '#fetch' do
    let(:fetcher) { TestResultsFetcher.new }
    let(:test_var_dir) { File.join(Dir.tmpdir, 'testResults_fetcher_test') }

    before do
      allow(described_class).to receive(:var_dir).and_return(test_var_dir)
      FileUtils.mkdir_p(test_var_dir)
    end

    after do
      FileUtils.rm_rf(test_var_dir)
    end

    it 'fetches and processes test results from https://morph.io/ianheggie-oaf/',
       vcr: { cassette_name: cassette_name('test_results_list') } do
      testResults = fetcher.fetch

      expect(testResults).to be_an(Array)
      expect(testResults.size).to be > 2 # Should have many testResults

      # Check the structure of testResults
      #
      # <div class="scraper-block">
      # <small class="scraper-lang pull-right">Ruby</small>
      # <div class="icon-box pull-right"><i class="fa fa-clock-o has-tooltip" data-placement="bottom" data-title="Scraper runs automatically once per day" data-original-title="" title=""></i>
      # </div>
      # <span class="label label-danger pull-right">errored</span>
      # <strong class="full_name">multiple_civica-prs</strong>
      # <div>
      # Test All civica pull requests
      # </div>
      # </div>
      testResults.each do |test_result|
        expect(test_result).to include('lang', 'auto_run', 'errored', 'description', 'full_name', 'running')

        expect(test_result['lang']).to be_a(String)
        expect(test_result['auto_run']).to be_a(Boolean)
        expect(test_result['errored']).to be_a(Boolean)
        expect(test_result['description']).to be_a(String)
        expect(test_result['full_name']).to be_a(String)
        expect(test_result['running']).to be_a(Boolean)
      end
    end
  end
end
