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
end
