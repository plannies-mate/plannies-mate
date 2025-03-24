# frozen_string_literal: true

require_relative '../spec_helper'
require_relative '../../app/matchers/issue_authority_matcher'

RSpec.describe IssueAuthorityMatcher do
  describe '.match' do
    before do
      # Create test data
      # Create scrapers and associate with authorities
      @masterview_scraper = Scraper.create!(
        github_url: 'https://github.com/planningalerts-scrapers/multiple_masterview',
        morph_url: 'https://morph.io/planningalerts-scrapers/multiple_masterview'
      )
      @sydney_scraper = Scraper.create!(
        github_url: 'https://github.com/planningalerts-scrapers/sydney_custom',
        morph_url: 'https://morph.io/planningalerts-scrapers/sydney_custom'
      )
      @port_melbourne_scraper = Scraper.create!(
        github_url: 'https://github.com/planningalerts-scrapers/port_melbourne',
        morph_url: 'https://morph.io/planningalerts-scrapers/port_melbourne'
      )
      @sydney = Authority.create!(name: 'City of Sydney', state: 'NSW', short_name: 'sydney',
                                  url: 'https://www.cityofsydney.org/', scraper: @sydney_scraper)
      @melbourne = Authority.create!(name: 'City of Melbourne', state: 'VIC', short_name: 'melbourne',
                                     url: 'https://www.melbourne.org/', scraper: @masterview_scraper)
      @port_melbourne = Authority.create!(name: 'Port Melbourne', state: 'VIC', short_name: 'port_melbourne',
                                          url: 'https://www.melbourne.org/', scraper: @port_melbourne_scraper)
      @brisbane = Authority.create!(name: 'Brisbane City Council', state: 'QLD', short_name: 'brisbane',
                                    url: 'https://brisbane.example.net/', scraper: @masterview_scraper)
    end

    it 'finds authority by exact name match' do
      authority = IssueAuthorityMatcher.match('City of Sydney')
      expect(authority).to eq(@sydney)
    end

    it 'finds authority by one of the words being unique' do
      authority = IssueAuthorityMatcher.match('Sydney Council issues')
      expect(authority).to eq(@sydney)
    end

    it 'finds authority with label-guided search' do
      authority = IssueAuthorityMatcher.match('Melbourne', %w[good-site masterview])
      expect(authority).to eq(@melbourne)
    end

    it 'returns nil when there are no unique matches' do
      authority = IssueAuthorityMatcher.match('issues for City Council', %w[good-site])
      expect(authority).to be_nil # Not specific enough
    end

    it 'returns nil when there are too many matches' do
      authority = IssueAuthorityMatcher.match('Brisbane Sydney', %w[good-site])
      expect(authority).to be_nil # Not specific enough
    end

    it 'returns nil when there are no uncommon words in title' do
      authority = IssueAuthorityMatcher.match('a City of south victoria', ['bad-site'])
      expect(authority).to be_nil # Not specific enough
    end

    it 'returns authority when label restricts authority list sufficiently' do
      authority = IssueAuthorityMatcher.match('Melbourne Sydney', %w[good-site masterview])
      expect(authority&.short_name).to eq(@melbourne.short_name)
    end

    it 'returns nil when no good match is found' do
      authority = IssueAuthorityMatcher.match('Something completely different')
      expect(authority).to be_nil
    end
  end
end
