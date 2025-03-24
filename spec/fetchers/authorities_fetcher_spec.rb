# frozen_string_literal: true

require_relative '../spec_helper'
require_relative '../../app/fetchers/authorities_fetcher'

RSpec.describe AuthoritiesFetcher do
  describe '#fetch' do
    let(:fetcher) { AuthoritiesFetcher.new }
    let(:test_var_dir) { File.join(Dir.tmpdir, 'authorities_fetcher_test') }

    before do
      allow(described_class).to receive(:var_dir).and_return(test_var_dir)
      FileUtils.mkdir_p(test_var_dir)
    end

    after do
      FileUtils.rm_rf(test_var_dir)
    end

    it 'fetches and processes planning authorities', vcr: { cassette_name: cassette_name('authorities_list') } do
      authorities = fetcher.fetch

      expect(authorities).to be_an(Array)
      expect(authorities.size).to be > 10 # Should have many authorities

      # Check the structure of authorities
      authorities.each do |authority|
        expect(authority).to include('state', 'name', 'url', 'short_name')
        expect(authority['state']).to be_a(String)
        expect(authority['name']).to be_a(String)
        expect(authority['url']).to include('https://www.planningalerts.org.au/authorities/')
        expect(authority['short_name']).to be_a(String)
        expect(authority).to have_key('population')
      end
    end
  end
end

