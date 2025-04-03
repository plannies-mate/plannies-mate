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

  %w[
    20250115150208
    20240116144246
    20230201051459
    20220127225057
    20210123100503
    20200301081915
    20190301045654
  ].each do |snapshot|
    describe "#fetch_snapshot of #{snapshot}", vcr: { cassette_name: cassette_name("snapshot_#{snapshot}") } do
      it 'fetches and processes state, authority, population and possibly broken labels' do
        # Use a real timestamp that exists in the VCR cassette
        authorities = fetcher.fetch_snapshot(snapshot)

        expect(authorities).to be_an(Array)
        expect(authorities.size).to be > 100

        # Check the structure matches what we expect
        broken = 0
        authorities.each do |authority|
          expect(authority).to include('state', 'name', 'population', 'possibly_broken', 'short_name')
          broken += 1 if authority['possibly_broken']
        end
        expect(broken).to be > 30
      end
    end
  end

  # %w[20180313211051 20170218223403 20160302131413 20150316150700].each do |snapshot|
  #   describe "#fetch_snapshot of #{snapshot}",
  #            vcr: { cassette_name: cassette_name("snapshot_#{snapshot}") } do
  #     it 'fetches and processes authority and possibly broken labels' do
  #       # Use a real timestamp that exists in the VCR cassette
  #       authorities = fetcher.fetch_snapshot(snapshot)
  #
  #       expect(authorities).to be_an(Array)
  #       expect(authorities.size).to be > 0
  #       broken = 0
  #       # Check the structure matches what we expect
  #       authorities.each do |authority|
  #         expect(authority).to include('name', 'possibly_broken', 'short_name')
  #         broken += 1 if authority['possibly_broken']
  #       end
  #       expect(broken).to be > 900
  #     end
  #   end
  # end

  # 2014 has internal scrapers
end
