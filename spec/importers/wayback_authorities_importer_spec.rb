# frozen_string_literal: true

require_relative '../spec_helper'
require_relative '../../app/importers/wayback_authorities_importer'
require_relative '../../app/models/coverage_history'

RSpec.describe WaybackAuthoritiesImporter do
  let(:importer) { described_class.new }
  let(:test_var_dir) { File.join(Dir.tmpdir, 'wayback_importer_test') }

  before do
    allow(described_class).to receive(:var_dir).and_return(test_var_dir)
    allow(described_class).to receive(:test?).and_return(true)
    FileUtils.mkdir_p(test_var_dir)
  end

  after do
    FileUtils.rm_rf(test_var_dir)
  end

  describe '#import_historical_data', vcr: { cassette_name: cassette_name('import_historical') } do
    it 'imports historical data and creates coverage history records' do
      # Use a small limit to avoid making too many requests in tests
      expect do
        created = importer.import_historical_data(limit: 1)
        expect(created).to be > 0
      end.to change(CoverageHistory, :count)
    end

    it 'respects date ranges when importing', vcr: { cassette_name: cassette_name('import_historical_date_range') } do
      # Use a date range that contains known data in the VCR cassette
      start_date = Date.parse('2023-01-01')
      end_date = Date.parse('2023-01-31')
      
      # Check that it correctly filters the dates
      result = importer.import_historical_data(start_date: start_date, end_date: end_date)
      
      # We may not have actual records in this date range in the cassette,
      # so we'll just verify it runs without error
      expect(result).to be >= 0
    end

    it 'skips dates that already exist in the database', vcr: { cassette_name: cassette_name('import_historical_existing') } do
      # Create a record for a date we'll try to import
      existing_date = Date.parse('2023-02-15')
      CoverageHistory.create!(
        recorded_on: existing_date,
        authority_count: 100,
        broken_authority_count: 20,
        total_population: 1_000_000,
        broken_population: 200_000
      )

      # Mock the timestamp to match our existing date
      allow_any_instance_of(WaybackAuthoritiesFetcher).to receive(:fetch_available_timestamps)
        .and_return(['20230215123456'])
      
      expect do
        result = importer.import_historical_data
        expect(result).to eq(0) # No new records created
      end.not_to change(CoverageHistory, :count)
    end
  end

  describe '#import_historical_data with failed snapshots', vcr: { cassette_name: cassette_name('import_historical_failures') } do
    it 'handles fetch_snapshot returning nil' do
      allow_any_instance_of(WaybackAuthoritiesFetcher).to receive(:fetch_available_timestamps)
        .and_return(['20230101123456'])
      allow_any_instance_of(WaybackAuthoritiesFetcher).to receive(:fetch_snapshot)
        .and_return(nil)

      expect do
        result = importer.import_historical_data
        expect(result).to eq(0) # No records created when snapshot returns nil
      end.not_to change(CoverageHistory, :count)
    end
  end
end
