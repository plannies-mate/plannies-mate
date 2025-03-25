# frozen_string_literal: true

require_relative '../spec_helper'
require_relative '../../app/fetchers/wayback_authorities_fetcher'
require_relative '../../app/models/coverage_history'

RSpec.describe WaybackAuthoritiesFetcher do
  let(:fetcher) { described_class.new }
  let(:test_var_dir) { File.join(Dir.tmpdir, 'wayback_fetcher_test') }

  before do
    allow(described_class).to receive(:var_dir).and_return(test_var_dir)
    FileUtils.mkdir_p(test_var_dir)
  end

  after do
    FileUtils.rm_rf(test_var_dir)
  end

  describe '#fetch_available_timestamps', vcr: { cassette_name: cassette_name('available_timestamps') } do
    it 'fetches timestamps from the Wayback Machine' do
      timestamps = fetcher.fetch_available_timestamps

      expect(timestamps).to be_an(Array)
      expect(timestamps.size).to be > 0

      # Test timestamp format (YYYYMMDDHHMMSS)
      timestamps.each do |timestamp|
        expect(timestamp).to match(/^\d{14}$/)
      end
    end
  end

  describe '#fetch_snapshot', vcr: { cassette_name: cassette_name('snapshot_20240315123456') } do
    it 'fetches and processes a historical snapshot' do
      # Use a real timestamp that exists in the VCR cassette
      authorities = fetcher.fetch_snapshot('20240315123456')

      expect(authorities).to be_an(Array)
      expect(authorities.size).to be > 0

      # Check the structure matches what we expect
      authorities.each do |authority|
        expect(authority).to include('state', 'name', 'url', 'short_name')
      end
    end
  end

  describe '#import_historical_data', vcr: { cassette_name: cassette_name('import_historical') } do
    it 'imports historical data and creates coverage history records' do
      # Mock fetch_available_timestamps to return a controlled set
      allow(fetcher).to receive(:fetch_available_timestamps).and_return(['20240315123456'])

      # Mock fetch_snapshot to return some sample data
      allow(fetcher).to receive(:fetch_snapshot).with('20240315123456').and_return([
                                                                                     {
                                                                                       'short_name' => 'test',
                                                                                       'possibly_broken' => true,
                                                                                       'population' => 50_000,
                                                                                     },
                                                                                     {
                                                                                       'short_name' => 'test2',
                                                                                       'possibly_broken' => false,
                                                                                       'population' => 100_000,
                                                                                     },
                                                                                   ])

      # Count the change in CoverageHistory records
      expect do
        created = fetcher.import_historical_data(limit: 1)
        expect(created).to be > 0
      end.to change(CoverageHistory, :count)
    end

    it 'respects date ranges when importing' do
      # Use a date range that contains known data in the VCR cassette
      start_date = Date.parse('2023-01-01')
      end_date = Date.parse('2023-01-31')

      allow(fetcher).to receive(:fetch_available_timestamps).and_return([
                                                                          '20221225123456', # Before start_date
                                                                          '20230115123456', # Within range
                                                                          '20230215123456', # After end_date
                                                                        ])

      # Mock fetch_snapshot to return some test data
      allow(fetcher).to receive(:fetch_snapshot).and_return([
                                                              { 'short_name' => 'test', 'possibly_broken' => false,
                                                                'population' => 100_000, },
                                                            ])

      # Should only process the middle timestamp
      expect(fetcher).to receive(:fetch_snapshot).with('20230115123456').once.and_call_original
      expect(fetcher).not_to receive(:fetch_snapshot).with('20221225123456')
      expect(fetcher).not_to receive(:fetch_snapshot).with('20230215123456')

      fetcher.import_historical_data(start_date: start_date, end_date: end_date)
    end

    it 'skips dates that already exist in the database' do
      # Create a record for a date we'll try to import
      existing_date = Date.parse('2023-02-15')
      CoverageHistory.create!(
        recorded_on: existing_date,
        authority_count: 100,
        broken_authority_count: 20,
        total_population: 1_000_000,
        broken_population: 200_000
      )

      allow(fetcher).to receive(:fetch_available_timestamps).and_return([
                                                                          '20230215123456', # Date already exists
                                                                        ])

      # Should not even try to fetch the snapshot
      expect(fetcher).not_to receive(:fetch_snapshot)

      result = fetcher.import_historical_data
      expect(result).to eq(0) # No new records created
    end

    it 'handles fetch_snapshot returning nil' do
      allow(fetcher).to receive(:fetch_available_timestamps).and_return(['20230101123456'])
      allow(fetcher).to receive(:fetch_snapshot).and_return(nil)

      result = fetcher.import_historical_data
      expect(result).to eq(0) # No records created when snapshot returns nil
    end

    it 'optimizes storage after importing data' do
      allow(fetcher).to receive(:fetch_available_timestamps).and_return(['20230101123456'])
      allow(fetcher).to receive(:fetch_snapshot).and_return([
                                                              { 'short_name' => 'test', 'possibly_broken' => false,
                                                                'population' => 100_000, },
                                                            ])

      # Expect optimize_storage to be called
      expect(CoverageHistory).to receive(:optimize_storage)

      fetcher.import_historical_data
    end
  end
end
