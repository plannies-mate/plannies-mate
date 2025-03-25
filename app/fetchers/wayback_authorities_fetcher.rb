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

  # Fetch and process snapshots, creating CoverageHistory records
  # @param limit [Integer, nil] Maximum number of snapshots to process, nil for all
  # @param start_date [Date, nil] Optional start date to limit historical data
  # @param end_date [Date, nil] Optional end date to limit historical data
  # @return [Array] An array of hashes with each hash having attributes for
  def import_historical_data(limit: nil, start_date: nil, end_date: nil)
    timestamps = fetch_available_timestamps

    # Filter by date range if provided
    if start_date || end_date
      timestamps = timestamps.select do |ts|
        date = Date.parse(ts[0..7])
        (start_date.nil? || date >= start_date) && (end_date.nil? || date <= end_date)
      end
    end

    timestamps = timestamps.take(limit) if limit

    return 0 if timestamps.empty?

    created_count = 0

    # Process in batches to avoid overwhelming the Wayback Machine
    timestamps.each_slice(BATCH_SIZE) do |batch|
      batch.each do |timestamp|
        # Convert timestamp to date
        date = Date.parse(timestamp[0..7])

        # Skip if we already have a record for this date
        next if CoverageHistory.exists?(recorded_on: date)

        authorities = fetch_snapshot(timestamp)
        next unless authorities

        # Create a coverage history record
        history = CoverageHistory.new(
          recorded_on: date,
          authority_count: authorities.size,
          broken_authority_count: authorities.count { |a| a['possibly_broken'] },
          total_population: authorities.sum { |a| a['population'].to_i },
          broken_population: authorities.select { |a| a['possibly_broken'] }
                                       .sum { |a| a['population'].to_i }
        )

        if history.save
          created_count += 1
          self.class.log "Created coverage history for #{date}"
        else
          self.class.log "Failed to save coverage history for #{date}: #{history.errors.full_messages.join(', ')}"
        end

        # Be polite to the Wayback Machine
        sleep 1
      end

      # Add a longer pause between batches
      sleep 5
    end

    # Optimize storage after importing historical data
    CoverageHistory.optimize_storage if created_count > 0

    created_count
  end
end
