# frozen_string_literal: true

require 'mechanize'
require 'json'
require 'fileutils'
require_relative '../helpers/application_helper'
require_relative '../helpers/html_helper'
require_relative 'scraper_base'

# Class to scrape authority list from PlanningAlerts website
class TestResultsFetcher
  extend ApplicationHelper
  extend HtmlHelper
  extend ScraperBase

  TEST_RESULTS_URL = 'https://morph.io/ianheggie-oaf/'

  def initialize(agent = nil)
    @agent = agent || self.class.create_agent
  end

  # Return the list of all authorities from main planning alerts page
  #
  # @example:
  #   [
  #     {
  #       'lang' => 'ruby',
  #       'auto_run' => true,
  #       'errored' => false,
  #       'description' => 'Test All civica pull requests',
  #       'full_name' => 'multiple_civica-prs',
  #        'running' => false,
  #     },
  #     ...
  #   ]
  def fetch(force: false, agent: nil, url: TEST_RESULTS_URL)
    self.class.log "Fetching test_result data from #{url}"

    page = self.class.fetch_page_with_cache(url, agent: agent, force: force)

    return nil if page.nil?

    test_results = parse_test_results(page)
    self.class.log "Fetched #{test_results.size} test_results"
    test_results
  end

  private

  def parse_test_results(page)
    test_results = []
    rows = page.search('div.scraper-block')

    rows.each do |row|
      record = {}
      cells = row.search('td')
      next if cells.empty? || cells.length < 3

      cells[1]
      test_result_link = row.at('a')
      next unless test_result_link

      state = self.class.extract_text(cells[0])
      record['state'] = state if STATES.include?(state)
      record['name'] = self.class.extract_text(test_result_link)
      record['short_name'] = self.class.last_url_segment test_result_link['href']
      record['possibly_broken'] = self.class.extract_text(row).downcase.include?('possibly broken')
      record['population'] = self.class.extract_number(cells[2]&.text)
      test_results << record
    end

    authorities
  end
end
