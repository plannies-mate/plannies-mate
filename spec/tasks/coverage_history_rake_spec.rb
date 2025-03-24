# frozen_string_literal: true

require_relative '../spec_helper'
require 'rake'
# Required otherwise load_tasks is not defined below!?
load File.expand_path('../../app/tasks/coverage_history.rake', __dir__)

RSpec.describe 'coverage_history.rake tasks' do
  before do
    Rake::Task.tasks.each(&:reenable)
    Rake::Task.load_tasks if Rake::Task.tasks.empty?
  end

  after do
    RSpec::Mocks.space.reset_all
    Rake::Task.tasks.each(&:reenable)
  end

  describe 'coverage_history:import_current' do
    it 'calls import_current on CoverageHistoryImporter' do
      mock_importer = instance_double(CoverageHistoryImporter)
      mock_record = instance_double(CoverageHistory,
                                    recorded_on: Date.today,
                                    authority_count: 150,
                                    broken_authority_count: 30,
                                    broken_authority_percentage: 20.0,
                                    total_population: 23000000,
                                    coverage_percentage: 80.0)

      expect(CoverageHistoryImporter).to receive(:new).and_return(mock_importer)
      expect(mock_importer).to receive(:import_current).and_return(mock_record)

      Rake::Task['coverage_history:import_current'].invoke
    end
  end

  describe 'coverage_history:import_historical' do
    it 'calls import_historical_data on WaybackAuthoritiesFetcher' do
      mock_fetcher = instance_double(WaybackAuthoritiesFetcher)

      expect(WaybackAuthoritiesFetcher).to receive(:new).and_return(mock_fetcher)
      expect(mock_fetcher).to receive(:import_historical_data).with(limit: 5, start_date: Date.parse('2023-01-01'),
                                                                    end_date: Date.parse('2023-12-31')).and_return(3)

      Rake::Task['coverage_history:import_historical'].invoke('5', '2023-01-01', '2023-12-31')
      Rake::Task['coverage_history:import_historical'].reenable
    end

    it 'handles missing arguments' do
      mock_fetcher = instance_double(WaybackAuthoritiesFetcher)

      expect(WaybackAuthoritiesFetcher).to receive(:new).and_return(mock_fetcher)
      expect(mock_fetcher).to receive(:import_historical_data).with(limit: nil, start_date: nil,
                                                                    end_date: nil).and_return(5)

      Rake::Task['coverage_history:import_historical'].invoke
      Rake::Task['coverage_history:import_historical'].reenable
    end
  end

  describe 'coverage_history:optimize' do
    it 'calls optimize_storage on CoverageHistoryImporter' do
      mock_importer = instance_double(CoverageHistoryImporter)

      expect(CoverageHistoryImporter).to receive(:new).and_return(mock_importer)
      expect(mock_importer).to receive(:optimize_storage).and_return(2)

      Rake::Task['coverage_history:optimize'].invoke
    end
  end

  describe 'coverage_history:generate' do
    it 'calls generate on CoverageHistoryGenerator' do
      result = {
        histories: coverage_histories.values.sort_by(&:recorded_on),
        output_file: '/tmp/coverage_history.html',
      }

      expect(CoverageHistoryGenerator).to receive(:generate).and_return(result)

      Rake::Task['coverage_history:generate'].invoke
    end
  end
end
