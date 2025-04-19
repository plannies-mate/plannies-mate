# frozen_string_literal: true

require 'mechanize'
require 'json'
require 'fileutils'
require_relative '../helpers/application_helper'
require_relative '../helpers/html_helper'
require_relative 'scraper_base'

# Class to scrape test results list from morph.io
class TestResultsFetcher
  extend ApplicationHelper
  extend HtmlHelper
  extend ScraperBase

  TEST_RESULTS_URL = 'https://morph.io/ianheggie-oaf/'

  def initialize(agent = nil)
    @agent = agent || self.class.create_agent
    @details_fetcher = TestResultDetailsFetcher.new(@agent)
    @details_cache = {}
  end

  # Return the list of all test results from morph.io
  #
  # @example:
  #   [
  #     {
  #       'lang' => 'ruby',
  #       'auto_run' => true,
  #       'errored' => false,
  #       'description' => 'Test All civica pull requests',
  #       'name' => 'multiple_civica-prs',
  #       'running' => false,
  #     },
  #     ...
  #   ]
  def fetch(agent: nil, url: TEST_RESULTS_URL)
    self.class.log "Fetching test_result data from #{url}"

    page = self.class.fetch_page(url, agent: agent)
    test_results = parse_test_results(page)

    self.class.log "Fetched #{test_results.size} valid test results"
    test_results
  end

  private

  def parse_test_results(page)
    test_results = []
    scraper_blocks = page.search('div.scraper-block')

    scraper_blocks.each do |block|
      record = {}

      lang_element = block.at('small.scraper-lang')
      record['lang'] = lang_element&.text&.strip
      record['auto_run'] = !block.at('i.fa-clock-o').nil?
      record['errored'] = !block.at('span.label-danger').nil?
      record['running'] = !block.at('div.running-indicator').nil?
      full_name_element = block.at('strong.full_name')
      record['name'] = full_name_element&.text&.strip
      description_div = block.search('div')&.last
      record['description'] = description_div&.text&.strip

      test_results << record unless ['', 'selfie-scraper'].include?(record['name'].to_s)
    end

    test_results
  end
end
