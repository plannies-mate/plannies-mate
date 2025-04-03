# frozen_string_literal: true

require 'spec_helper'
require_relative '../../app/importers/pull_requests_importer'

RSpec.describe PullRequestsImporter do
  let(:importer) { described_class.new }

  describe '#create_client' do
    context 'with token in ENV' do
      before do
        allow(ENV).to receive(:fetch).with('GITHUB_PERSONAL_TOKEN', nil).and_return('test_token')
      end

      it 'creates a client with authentication' do
        client = importer.create_client
        expect(client).to be_a(Octokit::Client)
        expect(client.access_token).to eq('test_token')
      end
    end

    context 'without token' do
      before do
        allow(ENV).to receive(:fetch).with('GITHUB_PERSONAL_TOKEN', nil).and_return(nil)
        allow(File).to receive(:size?).with('.env').and_return(nil)
      end

      it 'creates unauthenticated client' do
        client = importer.create_client
        expect(client).to be_a(Octokit::Client)
        expect(client.access_token).to be_nil
      end
    end
  end

  describe '#import', vcr: { cassette_name: 'pull_requests_importer/import' } do
    before do
      # Create test data
      FixtureHelper.find(User, :ianheggie_oaf) ||
        User.create!(
          id: 1234567,
          login: 'ianheggie-oaf',
          html_url: 'https://github.com/ianheggie-oaf'
        )

      FixtureHelper.find(Scraper, :multiple_masterview) ||
        Scraper.create!(
          name: 'multiple_masterview',
          github_url: 'https://github.com/planningalerts-scrapers/multiple_masterview'
        )
    end

    it 'imports pull requests for a user' do
      result = importer.import(users: 'ianheggie-oaf', since: Date.parse('2024-01-01'))

      expect(result[:errors]).to eq(0)
      expect(result[:imported] + result[:updated]).to be > 0
    end

    it 'associates PRs with authorities when possible' do
      FixtureHelper.find(Authority, :brimbank) ||
        Authority.create!(
          short_name: 'brimbank',
          scraper: Scraper.find_by(name: 'multiple_masterview')
        )

      importer.import(users: 'ianheggie-oaf', since: Date.parse('2024-01-01'))

      # Find PRs for multiple_masterview
      prs = PullRequest.joins(:scraper).where(scrapers: { name: 'multiple_masterview' })

      # At least some should be associated with authorities
      expect(prs.joins(:authorities).count).to be > 0
    end
  end

  describe '#guess_associated_authorities' do
    let(:scraper) { FixtureHelper.find(Scraper, :multiple_masterview) || Scraper.create!(name: 'multiple_masterview') }
    let(:authority) do
      FixtureHelper.find(Authority, :brimbank) || Authority.create!(short_name: 'brimbank', scraper: scraper)
    end
    let(:pull_request) { PullRequest.new(scraper: scraper) }

    before do
      # Create test data if not already present
      authority # ensure authority exists
    end

    it 'associates PR with authority based on repo name' do
      # Create a PR for a repo that matches an authority name
      pr = PullRequest.new(
        url: 'https://github.com/planningalerts-scrapers/brimbank/pull/1',
        scraper: FixtureHelper.find(Scraper, :brimbank) || Scraper.create!(name: 'brimbank')
      )

      importer.send(:guess_associated_authorities, pr, 'Test PR', 'brimbank')

      expect(pr.authorities).to include(authority)
    end

    it 'associates PR with authorities for multiple scrapers' do
      # Create authorities for multiple scraper
      authority2 = Authority.find_by(short_name: 'maribyrnong') ||
                   Authority.create!(short_name: 'maribyrnong', scraper: scraper)

      pr = PullRequest.new(
        url: 'https://github.com/planningalerts-scrapers/multiple_masterview/pull/1',
        scraper: scraper
      )

      importer.send(:guess_associated_authorities, pr, 'Fix multiple councils', 'multiple_masterview')

      expect(pr.authorities).to include(authority)
      expect(pr.authorities).to include(authority2) if authority2.persisted?
    end
  end
end
