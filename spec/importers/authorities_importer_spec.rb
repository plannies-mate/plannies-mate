# frozen_string_literal: true

require_relative '../spec_helper'
require_relative '../../app/importers/authorities_importer'

RSpec.describe AuthoritiesImporter do
  before do
    @importer = described_class.new
  end

  context 'importing from scratch' do
    before do
      Fixture.clear_database
    end

    it 'imports authorities and scrapers', vcr: { cassette_name: cassette_name('import_authorities_from_scratch') } do
      @importer.import

      count = Authority.count
      expect(count).to be > 100
    end
  end

  # # FIXME: use less mocking!!!
  # context 'when updating unchanged authorities' do
  #   # Use a separate context to avoid conflicts with the existing before block
  #   let(:importer) { described_class.new }
  #
  #   before do
  #     # Create a test authority
  #     @authority = Authority.create!(
  #       short_name: 'test_auth',
  #       name: 'Test Authority',
  #       url: 'https://example.com/test',
  #       scraper: Scraper.create!(name: 'test_scraper')
  #     )
  #
  #     # Setup mocks for fetchers
  #     allow(importer.instance_variable_get(:@details_fetcher)).to receive(:fetch)
  #       .with('test_auth')
  #       .and_return({'name' => 'Test Authority'})
  #
  #     allow(importer.instance_variable_get(:@stats_fetcher)).to receive(:fetch)
  #       .with('test_auth')
  #       .and_return({'total_count' => 0})
  #   end
  #
  #   it 'skips updating unchanged authorities' do
  #     # Setup authority to report no changes
  #     allow_any_instance_of(Authority).to receive(:changed?).and_return(false)
  #
  #     # Reset the counters
  #     importer.instance_variable_set(:@count, 0)
  #     importer.instance_variable_set(:@changed, 0)
  #
  #     # Mock Authority.all to only return our test authority
  #     allow(Authority).to receive(:all).and_return([@authority])
  #
  #     # Mock list_fetcher to simulate unchanged list
  #     allow(importer.instance_variable_get(:@list_fetcher)).to receive(:fetch).and_return(nil)
  #
  #     # Capture output
  #     expect { importer.import }.to output(/Updated 0 of 1 authorities/).to_stdout
  #
  #     # Verify counters
  #     expect(importer.count).to eq(1)
  #     expect(importer.changed).to eq(0)
  #   end
  # end
end
