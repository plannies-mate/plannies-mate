# frozen_string_literal: true

require_relative '../spec_helper'
require_relative '../../app/fetchers/authority_stats_fetcher'

RSpec.describe AuthorityStatsFetcher do
  describe '#fetch', vcr: { cassette_name: cassette_name('fetches stats') } do
    let(:fetcher) { AuthorityStatsFetcher.new }
    let(:test_var_dir) { File.join(Dir.tmpdir, 'authority_stats_test') }
    let(:short_name) { 'sydney' }

    before do
      allow(described_class).to receive(:var_dir).and_return(test_var_dir)
      FileUtils.mkdir_p(test_var_dir)
    end

    after do
      FileUtils.rm_rf(test_var_dir)
    end

    it 'fetches stats' do
      stats = fetcher.fetch(short_name)
      expect(stats).to be_a(Hash)

      expect(stats).to include('short_name')
      expect(stats['short_name']).to eq(short_name)

      # Check for expected stats fields
      expect(stats).to have_key('week_count')
      expect(stats).to have_key('month_count')
      expect(stats).to have_key('total_count')
    end

    it 'requires a short_name' do
      expect { fetcher.fetch('') }.to raise_error(ArgumentError)
    end
  end
end
