# frozen_string_literal: true

require 'mechanize'
require 'json'
require 'fileutils'
require_relative '../helpers/application_helper'
require_relative 'scraper_base'

# Class to fetch historical authority data from Wayback Machine
class WaybackAuthoritiesFetcher
  extend ApplicationHelper
  extend ScraperBase

  # URL for the Wayback Machine CDX API for authorities page
  WAYBACK_CDX_URL = 'http://web.archive.org/cdx/search/cdx'

  # URL template for retrieving a specific snapshot
  WAYBACK_SNAPSHOT_URL = 'http://web.archive.org/web/{timestamp}/{url}'

  # Max number of timestamps per request to avoid overwhelming the service
  BATCH_SIZE = 20

  def initialize(agent = nil)
    @agent = agent || self.class.create_agent
    @authorities_fetcher = AuthoritiesFetcher.new(@agent)
  end

  # Get a list of available timestamps from the Wayback Machine
  # @return [Array<String>] List of timestamps in format YYYYMMDDHHMMSS
  def fetch_available_timestamps
    params = {
      url: AuthoritiesFetcher::AUTHORITIES_URL,
      output: 'json',
      collapse: 'timestamp:8', # Group by day to reduce results
    }

    url = "#{WAYBACK_CDX_URL}?#{URI.encode_www_form(params)}"
    self.class.log "Fetching available timestamps from #{url}"

    page = @agent.get(url)
    results = JSON.parse(page.body)

    # First row is headers, skip it
    timestamps = results[1..-1].map { |row| row[1] }
    self.class.log "Found #{timestamps.size} historical snapshots"

    timestamps
  end

  # Fetch historical data for a specific timestamp
  # @param timestamp [String] Wayback Machine timestamp in format YYYYMMDDHHMMSS
  # @return [Hash, nil] Processed authorities data or nil if error/no data
  def fetch_snapshot(timestamp)
    url = WAYBACK_SNAPSHOT_URL.sub('{timestamp}', timestamp)
                              .sub('{url}', AuthoritiesFetcher::AUTHORITIES_URL)

    self.class.log "Fetching historical snapshot from #{url}"

    begin
      # Use the authorities fetcher to process the page
      authorities = @authorities_fetcher.fetch(url: url, force: true, agent: @agent)

      if authorities && !authorities.empty?
        self.class.log "Successfully processed historical snapshot with #{authorities.size} authorities"
        authorities
      else
        self.class.log 'No valid authorities data found in historical snapshot'
        nil
      end
    rescue StandardError => e
      self.class.log "Error fetching historical snapshot: #{e.message}"
      nil
    end
  end
end
