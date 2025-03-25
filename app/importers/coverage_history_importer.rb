# frozen_string_literal: true

# Imports and tracks coverage history data from current and historical authority data
class CoverageHistoryImporter
  attr_reader :count, :changed

  def initialize
    @list_fetcher = AuthoritiesFetcher.new
    @count = @changed = 0
  end

  # Called from authorities importer to add current coverage after fetching authorities
  def self.update_from_authorities(authorities)
    return if authorities.nil? || authorities.empty?

    today = Date.today
    existing = CoverageHistory.find_by(recorded_on: today)

    if existing
      puts "Coverage history for #{today} already exists"
      existing
    else
      history = CoverageHistory.create_from_authorities(authorities)
      puts "Added coverage history for #{today}" if history
      history
    end
  end

  # Optimize storage by removing redundant records
  def optimize_storage
    removed = CoverageHistory.optimize_storage
    puts "Removed #{removed} redundant coverage history records"
    removed
  end
end
