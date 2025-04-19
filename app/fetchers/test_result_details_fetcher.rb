# frozen_string_literal: true

require 'mechanize'
require 'json'
require 'fileutils'
require_relative '../helpers/application_helper'
require_relative '../helpers/html_helper'
require_relative 'scraper_base'

# Class to fetch detailed information for test results from morph.io
class TestResultDetailsFetcher
  extend ApplicationHelper
  extend HtmlHelper
  extend ScraperBase

  BASE_URL = 'https://morph.io/'

  def initialize(agent = nil)
    @agent = agent || self.class.create_agent
    @fetched = []
  end

  # Returns Details of a test result
  #
  # @param name [String] The name of the test result (repository) on morph.io
  # @param force [Boolean] Whether to force refresh cache
  # @return [Hash<String, String>, nil] Array of unique authority names or nil if it hasn't changed
  #
  # @example:
  #   {
  #     "name": "multiple_civica-prs",
  #     "failed": true,
  #     "run_at": "2025-04-17T05:29:59Z",
  #     "revision": "9e37d08579df709b3ae6efc1c101c64bad6376e9",
  #     "run_time": "7 minutes",
  #     "records_added": 414,
  #     "records_removed": 379,
  #     "console_output": "Scraping authorities: bunbury, burwood, camden, cairns...",
  #     "successful_authorities": ["bunbury", "camden", "cairns", "lane_cove", "vincent", "woollahra"],
  #     "failed_authorities": ["burwood", "dorset", "nambucca", "orange", "wanneroo", "whittlesea"],
  #     "interrupted_authorities": [],
  #     "tables": ["data", "scrape_log", "scrape_summary"],
  #     "has_authority_label_column": true,
  #     "required_fields_present": true
  #   }
  def fetch(name, force: false)
    @fetched << name
    raise(ArgumentError, 'Must supply name') if name.blank?

    # Parse owner/repo format
    parts = name.split('/')
    if parts.size > 1
      owner = parts[0]
      repo = parts[1]
    else
      owner = 'ianheggie-oaf'
      repo = name
    end

    url = "#{BASE_URL}#{owner}/#{repo}"

    page = self.class.fetch_page(url, agent: @agent, force: force)

    return nil if page.nil?

    details = parse_details(page, name)

    self.class.log "Fetched details for test result #{name}"
    details
  end

  private

  # Return nil if test hasn't been run
  def parse_details(page, name)
    details = { 'name' => name }

    data_section = page.at('#data-table')
    # Not run OR not a data scraper
    return nil unless data_section

    details['tables'] = extract_available_tables(data_section)

    extract_data_table(data_section, details, page.uri)
    extract_scrape_summary_table(data_section, details, page.uri)
    extract_latest_history(page, details)

    details
  end

  def extract_available_tables(page)
    tables = []
    nav_tabs = page.search('.nav-tabs a')
    nav_tabs.each do |tab|
      href = tab['href']
      next unless href

      tables << ::Regexp.last_match(1) if href =~ /#table_(\w+)/
    end
    tables
  end

  def authority_label?(data_tab)
    return false if data_tab.nil?

    headers = data_tab.search('thead th')
    headers.any? { |h| h.text.strip == 'authority_label' }
  end

  def extract_data_table(data_section, details, uri)
    data_tab_content = data_section.at('#table_data')
    raise "Missing data table tab for #{uri}" unless data_tab_content

    details['has_authority_label'] = authority_label?(data_tab_content)
    required_fields = %w[council_reference address description info_url date_scraped]
    headers = data_tab_content.search('thead th').map { |h| h.text.strip }
    missing_fields = required_fields - headers

    raise "Missing required fields: #{missing_fields.join(', ')} for #{uri}" if missing_fields.any?
  end

  def extract_scrape_summary_table(section, details, uri)
    table_body = section.at('#table_scrape_summary tbody')
    header_cells = section.search('#table_scrape_summary thead th').map { |th| th.text.strip.downcase }
    return unless table_body && header_cells&.any?

    successful_idx = header_cells.index('successful')
    failed_idx = header_cells.index('failed')
    interrupted_idx = header_cells.index('interrupted')
    unless successful_idx && failed_idx && interrupted_idx
      raise "Missing expected column in scrape_summary table on #{uri}"
    end

    ignored_idx = header_cells.index('ignored')

    first_row = table_body.at('tr')
    raise "Unable to find tbody > tr on #{uri}" unless first_row

    cells = first_row.search('td div.has-popover')
    raise "Unable to find d div.has-popover on #{uri}" unless cells && cells.length >= 6

    successful = cells[successful_idx].text.strip
    details['successful_authorities'] = successful.split(',').map(&:strip)
    failed = cells[failed_idx].text.strip
    details['failed_authorities'] = failed.split(',').map(&:strip)
    interrupted = cells[interrupted_idx].text.strip
    details['interrupted_authorities'] = interrupted.split(',').map(&:strip)
    ignored = cells[ignored_idx].text.strip if ignored_idx
    details['ignored_authorities'] = ignored.split(',').map(&:strip) if ignored
  end

  def extract_latest_history(page, details)
    history_item = page.at('#history .list-group-item')
    raise "Missing history item for page #{page.uri}" unless history_item

    # Extract revision (git commit)
    rev_link = history_item.at('a[href*="commit"]')
    raise "Missing rev_link for first history entry on #{page.uri}" unless rev_link

    details['revision'] = rev_link['href'].split('/').last

    run_time_div = history_item.at('.pull-right div:first-child')
    details['run_time'] = run_time_div.text.strip.sub(/run time\s*/, '') if run_time_div

    details['failed'] = case
                        when history_item.classes.include?('alert-danger')
                          true
                        when history_item.classes.include?('alert-success')
                          false
                        else
                          raise "Unable to determine status from first history item on #{page.uri}"
                        end
    time_element = history_item.at('time')
    raise "Unable to find time run_at in history item on #{page.uri}" unless time_element

    details['run_at'] = time_element['datetime']
  end
end
