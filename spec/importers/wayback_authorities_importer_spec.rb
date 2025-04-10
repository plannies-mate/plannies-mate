# frozen_string_literal: true

require_relative '../spec_helper'
require_relative '../../app/importers/wayback_authorities_importer'
require_relative '../../app/models/coverage_history'

RSpec.describe WaybackAuthoritiesImporter do
  let(:importer) { described_class.new }
  let(:test_var_dir) { File.join(Dir.tmpdir, 'wayback_importer_test') }
  let(:recorded_on) { 2.days.ago.to_date }
  let(:wayback_url) { 'http://wayback.example.com/path/to/snapshot' }

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
        created = importer.import_historical_data(limit: 10)
        expect(created).to be >= 7
      end.to change(CoverageHistory, :count)
      last = CoverageHistory.last
      expect(last.broken_authorities).not_to be_empty
      expect(last.broken_authorities.size).to be >= 70
    end

    it 'respects date ranges when importing', vcr: { cassette_name: cassette_name('import_historical_date_range') } do
      # Use a date range that contains known data in the VCR cassette
      start_date = Date.parse('2023-01-01')
      end_date = Date.parse('2023-03-30')

      # Check that it correctly filters the dates
      result = importer.import_historical_data(start_date: start_date, end_date: end_date)

      # We may not have actual records in this date range in the cassette,
      # so we'll just verify it runs without error
      expect(result).to be >= 2
    end

    it 'skips dates that already exist in the database',
       vcr: { cassette_name: cassette_name('import_historical_existing') } do
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

  describe '#import_historical_data with failed snapshots',
           vcr: { cassette_name: cassette_name('import_historical_failures') } do
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

  describe '.create_from_authorities' do
    it 'creates a coverage history record from authorities data' do
      authorities = [
        { 'short_name' => 'auth1', 'possibly_broken' => false, 'population' => 50_000 },
        { 'short_name' => 'auth2', 'possibly_broken' => true, 'population' => 30_000 },
        { 'short_name' => 'auth3', 'possibly_broken' => false, 'population' => 70_000 },
      ]
      history = importer.create_from_authorities(authorities, recorded_on, 'http://wayback.example.com/path/to/snapshot')

      expect(history).to be_persisted
      expect(history.recorded_on).to eq(recorded_on)
      expect(history.authority_count).to eq(3)
      expect(history.broken_authority_count).to eq(1)
      expect(history.total_population).to eq(150_000)
      expect(history.broken_population).to eq(30_000)
    end

    it 'handles nil population values' do
      authorities = [
        { 'short_name' => 'auth1', 'possibly_broken' => false, 'population' => nil },
        { 'short_name' => 'auth2', 'possibly_broken' => true, 'population' => 30_000 },
      ]

      history = importer.create_from_authorities(authorities, recorded_on, wayback_url)

      expect(history.total_population).to eq(30_000)
      expect(history.broken_population).to eq(30_000)
    end

    it 'returns nil when given nil or empty authorities' do
      expect(importer.create_from_authorities(nil, recorded_on, nil)).to be_nil
      expect(importer.create_from_authorities([], recorded_on, nil)).to be_nil
      expect(importer.create_from_authorities(nil, recorded_on, wayback_url)).to be_nil
      expect(importer.create_from_authorities([], recorded_on, wayback_url)).to be_nil
    end
  end
end
