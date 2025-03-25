# frozen_string_literal: true

require_relative '../fetchers/wayback_authorities_fetcher'
require_relative '../helpers/application_helper'
require_relative '../models/coverage_history'

# Imports historical authority data from Wayback Machine
class WaybackAuthoritiesImporter
  extend ApplicationHelper

  attr_reader :fetcher, :count

  # Initialize with optional fetcher
  def initialize(fetcher = nil)
    @fetcher = fetcher || WaybackAuthoritiesFetcher.new
    @count = 0
  end

  # Import historical data from Wayback Machine
  # @param limit [Integer, nil] Maximum number of snapshots to process, nil for all
  # @param start_date [Date, nil] Optional start date to limit historical data
  # @param end_date [Date, nil] Optional end date to limit historical data
  # @return [Integer] The number of records created
  def import_historical_data(limit: nil, start_date: nil, end_date: nil)
    timestamps = @fetcher.fetch_available_timestamps

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
    timestamps.each_slice(WaybackAuthoritiesFetcher::BATCH_SIZE) do |batch|
      batch.each do |timestamp|
        # Convert timestamp to date
        date = Date.parse(timestamp[0..7])

        # Skip if we already have a record for this date
        next if CoverageHistory.exists?(recorded_on: date)

        authorities = @fetcher.fetch_snapshot(timestamp)
        next unless authorities

        # Create a coverage history record
        history = CoverageHistory.create_from_authorities(authorities)
        history.update(recorded_on: date) if history # Override with historical date

        if history&.persisted?
          created_count += 1
          self.class.log "Created coverage history for #{date}"
        else
          self.class.log "Failed to save coverage history for #{date}"
        end

        # Be polite to the Wayback Machine
        sleep 1 unless self.class.test?
      end

      # Add a longer pause between batches
      sleep 5 unless self.class.test?
    end

    # Optimize storage after importing historical data
    CoverageHistory.optimize_storage if created_count > 0

    @count = created_count
    created_count
  end
end
