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
    timestamps = @fetcher.fetch_available_timestamps(from: start_date, to: end_date)

    timestamps = timestamps.take(limit) if limit&.positive?

    return 0 if timestamps.empty?

    created_count = 0

    # Process in batches to avoid overwhelming the Wayback Machine
    timestamps.each_slice(WaybackAuthoritiesFetcher::BATCH_SIZE) do |batch|
      batch.each do |timestamp|
        # Convert timestamp to date
        date = Date.parse(timestamp[0..7])
        wayback_url = @fetcher.wayback_url(timestamp)

        # Skip if we already have a record for this date
        if CoverageHistory.exists?(recorded_on: date)
          puts "Skipping existing recorded_on: #{date}"
          next
        elsif CoverageHistory.exists?(wayback_url: wayback_url)
          puts "Skipping existing wayback_url: #{wayback_url}"
          next
        end

        authorities = @fetcher.fetch_snapshot(timestamp)
        next unless authorities

        # Create a coverage history record
        history = create_from_authorities(authorities, date, @fetcher.wayback_url(timestamp))

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
    CoverageHistory.optimize_storage if created_count.positive?

    @count = created_count
    created_count
  end

  # Create a record from authorities fetcher results
  def create_from_authorities(authorities, recorded_on, wayback_url)
    return nil unless authorities&.any?

    broken_authorities = authorities.select { |a| a['possibly_broken'] }
    # Calculate counts and population
    authority_count = authorities.size
    broken_count = broken_authorities.count

    # Sum populations, handling nil values
    total_pop = authorities.sum { |a| a['population'].to_i }
    broken_pop = broken_authorities.sum { |a| a['population'].to_i }

    # Create the record for today
    record = CoverageHistory.create(
      recorded_on: recorded_on,
      authority_count: authority_count,
      broken_authority_count: broken_count,
      total_population: total_pop,
      broken_population: broken_pop,
      wayback_url: wayback_url
    )

    if record.persisted?
      broken_authorities.each do |broken_authority|
        auth = Authority.find_or_create_by(short_name: broken_authority['short_name']) do |new_auth|
          new_auth.added_on = recorded_on
          # We found it for the first time
          new_auth.delisted_on = recorded_on.to_date + 1
          new_auth.name = broken_authority['name']
          new_auth.state = broken_authority['state']
          new_auth.possibly_broken = broken_authority['possibly_broken']
          new_auth.population = broken_authority['population']
        end
        # Extend the added_on date if we find it present earlier
        auth.update(added_on: recorded_on) if auth.added_on.nil? || auth.added_on > recorded_on
        if auth.delisted_on && auth.delisted_on <= recorded_on
          # it is present on a later date
          auth.update(delisted_on: wayback_url ? recorded_on.to_date + 1 : nil)
        end
        # {"state"=>"NSW", "name"=>"Albury City Council", "short_name"=>"albury", "possibly_broken"=>true, "population"=>56093}
        status = if !auth.persisted?
                   'FAILED to create and link'
                 elsif auth.new_record?
                   'Created and linked New'
                 else
                   'Linked Existing'
                 end
        puts "#{status}: #{broken_authority.inspect}"
        record.broken_authorities << auth if auth.persisted?
      end
    end
    record
  end
end
