# frozen_string_literal: true

require 'spec_helper'
require_relative '../../app/importers/pull_requests_importer'

RSpec.describe PullRequestsImporter do
  let(:importer) { described_class.new }

  describe '#import', vcr: { cassette_name: 'pull_requests_importer/import' } do
    before do
      @result = importer.import
    end

    it 'imports pull requests for MY_USER_NAME' do
      expect(@result[:errors]).to eq(0)
      expect(@result[:imported] + @result[:updated]).to be > 5
      expect(@result[:removed]).to be > 1
    end

    it 'associates PRs with issues when possible' do
      # Find PRs for multiple_masterview
      prs = PullRequest.joins(:scraper).where(scrapers: { name: 'multiple_masterview' })

      # Assert that at least one PR in `prs` has a non-nil issue
      prs_have_issues = prs.any? { |pr| pr.issue.present? }
      # puts "DEBUG prs: #{prs.map(&:attributes).to_yaml}" unless prs_have_issues
      # title: Added Burwood Council (ex civica)
      # title: Fix many broken authorities, add debugging tools and reports, update to heroku-18
      #     platform, and much more ... [Rejected Ben Hur]
      # puts "DEBUG ISSUES: #{Issue.pluck(:title).to_yaml}" unless prs_have_issues
      expect(prs_have_issues).to be true
    end
  end

  describe '#guess_associated_issue' do
    # let(:scraper) { FixtureHelper.find(Scraper, :multiple_masterview) || raise('Missing multiple_masterview fixture!') }
    # let(:authority) { FixtureHelper.find(Authority, :brimbank) || raise('Missing brimbank fixture!') }
    # let(:pull_request) { PullRequest.new(scraper: scraper, number: 987654) }

    # it 'Finds scraper.name => Authority.short_name, Authority.name => Issue.title' do
    # end

    # authority = Authority.find_by(short_name: scraper.name)
    #     issue = Issue.find_by(title: authority.name) if authority
    #     if issue
    #       pull_request.issue = issue
    #       self.class.log "Associated PR with issue: #{issue.title} via Authority.short_name == scraper.name"
    #       return
    #     end
    #
    #     authority = Authority.find_by(name: title)
    #     issue = Issue.find_by(title: authority.name) if authority
    #     if issue
    #       pull_request.issue = issue
    #       self.class.log "Associated PR with issue: #{issue.title} via Authority.name == title"
    #       return
    #     end
    #
    #     issue = scraper.issues
    #                    .sort_by { |i| -i.title.size }
    #                    .find { |i| title.include?(i.title) }
    #     return unless issue
    #
    #     pull_request.issue = issue
    #     self.class.log "Associated PR with issue: #{issue.title} via scraper.issues"

    # it 'associates PR with issue based on repo name',
    #    vcr: { cassette_name: 'pull_requests_importer/guess_associated_issue-bawbaw' } do
    #   # Create a PR for a repo that matches an authority name
    #   pr = PullRequest.new(
    #     number: 123,
    #     scraper: FixtureHelper.find(Scraper, :bawbaw)
    #   )
    #
    #   importer.send(:guess_associated_issue, pr, 'Test PR', 'bawbaw')
    #
    #   expect(pr.authorities).to include(authority)
    # end
    #
    # it 'associates PR with authorities for multiple scrapers',
    #    vcr: { cassette_name: 'pull_requests_importer/guess_associated_issue-multiple_masterview' } do
    #   # Create authorities for multiple scraper
    #   authority2 = Authority.find_by(short_name: 'maribyrnong') || raise('Missing fixture!')
    #
    #   pr = PullRequest.new(
    #     number: 1,
    #     scraper: scraper
    #   )
    #
    #   importer.send(:guess_associated_issue, pr, 'Fix multiple councils', 'multiple_masterview')
    #
    #   expect(pr.authorities).to include(authority)
    #   expect(pr.authorities).to include(authority2) if authority2.persisted?
    # end
  end
end
