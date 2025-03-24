# frozen_string_literal: true

require_relative '../spec_helper'
require_relative '../../app/importers/coverage_history_importer'
require_relative '../../app/fetchers/authorities_fetcher'

RSpec.describe CoverageHistoryImporter do
  before do
    @importer = described_class.new
  end

  describe '#import_current' do
    context 'when there is no record for today' do
      it 'creates a new record based on fetched authorities', vcr: { cassette_name: cassette_name('creates_new_record') } do
        expect do
          @importer.import_current
        end.to change(CoverageHistory, :count).by(1)

        record = CoverageHistory.find_by(recorded_on: Date.today)
        expect(record).not_to be_nil
        expect(record.authority_count).to be > 0
      end
    end

    context 'when there is already a record for today' do
      it 'does not create a duplicate record', vcr: { cassette_name: cassette_name('no_duplicate_records') } do
        travel_to Time.now do
          # Create record for today
          CoverageHistory.create!(
            recorded_on: Date.today,
            authority_count: 100,
            broken_authority_count: 20,
            total_population: 1_000_000,
            broken_population: 200_000
          )

          expect do
            result = @importer.import_current
            expect(result).not_to be_nil
          end.not_to change(CoverageHistory, :count)
        end
      end
    end

    context 'when fetcher returns no data' do
      it 'does not create a record' do
        allow_any_instance_of(AuthoritiesFetcher).to receive(:fetch).and_return(nil)

        expect do
          result = @importer.import_current
          expect(result).to be_nil
        end.not_to change(CoverageHistory, :count)
      end
    end
  end

  describe '.update_from_authorities' do
    it 'creates a record from provided authorities' do
      authorities = [
        { 'short_name' => 'auth1', 'possibly_broken' => false, 'population' => 50_000 },
        { 'short_name' => 'auth2', 'possibly_broken' => true, 'population' => 30_000 },
      ]

      travel_to Time.now do
        expect do
          described_class.update_from_authorities(authorities)
        end.to change(CoverageHistory, :count).by(1)

        record = CoverageHistory.find_by(recorded_on: Date.today)
        expect(record).not_to be_nil
        expect(record.authority_count).to eq(2)
        expect(record.broken_authority_count).to eq(1)
        expect(record.total_population).to eq(80_000)
        expect(record.broken_population).to eq(30_000)
      end
    end

    it 'does not create a duplicate record for the same day' do
      authorities = [
        { 'short_name' => 'auth1', 'possibly_broken' => false, 'population' => 50_000 },
      ]

      travel_to Time.now do
        CoverageHistory.create!(
          recorded_on: Date.today,
          authority_count: 100,
          broken_authority_count: 20,
          total_population: 1_000_000,
          broken_population: 200_000
        )

        expect do
          described_class.update_from_authorities(authorities)
        end.not_to change(CoverageHistory, :count)
      end
    end

    it 'returns nil when given nil or empty authorities' do
      expect(described_class.update_from_authorities(nil)).to be_nil
      expect(described_class.update_from_authorities([])).to be_nil
    end
  end

  describe '#optimize_storage' do
    it 'calls the model method and reports results' do
      # Use our fixture data which has identical1, identical2, identical3
      expect(CoverageHistory).to receive(:optimize_storage).and_return(1)

      expect do
        @importer.optimize_storage
      end.to output(/Removed 1 redundant coverage history records/).to_stdout
    end
  end
end
