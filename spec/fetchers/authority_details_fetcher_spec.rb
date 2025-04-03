# frozen_string_literal: true

require_relative '../spec_helper'
require_relative '../../app/fetchers/authority_details_fetcher'

RSpec.describe AuthorityDetailsFetcher do
  describe '#fetch', vcr: { cassette_name: cassette_name('authority_details/sydney') } do
    let(:fetcher) { AuthorityDetailsFetcher.new }
    let(:test_var_dir) { File.join(Dir.tmpdir, 'authority_details_test') }
    let(:short_name) { 'sydney' }

    before do
      allow(described_class).to receive(:var_dir).and_return(test_var_dir)
      FileUtils.mkdir_p(test_var_dir)
    end

    after do
      FileUtils.rm_rf(test_var_dir)
    end

    it 'fetches and processes authority details' do
      details = fetcher.fetch(short_name)
      expect(details).to be_a(Hash)

      expect(details).to include('short_name', 'repo')
      expect(details['short_name']).to eq(short_name)
    end

    it 'requires a short_name' do
      expect { fetcher.fetch('') }.to raise_error(ArgumentError)
    end
  end
end
