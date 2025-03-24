# frozen_string_literal: true

# Imports and tracks coverage history data from current and historical authority data
class CoverageHistoryImporter
  attr_reader :count, :changed

  def initialize
    @list_fetcher = AuthoritiesFetcher.new
    @count = @changed = 0
  end

  # Import current coverage statistics
  def import_current
    list = @list_fetcher.fetch
    if list && !list.empty?
      today = Date.today
      existing = CoverageHistory.find_by(recorded_on: today)
      
      if existing
        # We already have a record for today
        return existing
      else
        # Create a new record for today
        history = CoverageHistory.create_from_authorities(list)
        @count += 1
        @changed += 1
        puts "Added coverage history for #{today}"
        return history
      end
    else
      puts "No authority data available to create coverage history"
      return nil
    end
  end

  # Called from authorities importer to add current coverage after fetching authorities
  def self.update_from_authorities(authorities)
    return if authorities.nil? || authorities.empty?
    
    today = Date.today
    existing = CoverageHistory.find_by(recorded_on: today)
    
    if existing
      puts "Coverage history for #{today} already exists"
      return existing
    else
      history = CoverageHistory.create_from_authorities(authorities)
      puts "Added coverage history for #{today}" if history
      return history
    end
  end
  
  # Optimize storage by removing redundant records
  def optimize_storage
    removed = CoverageHistory.optimize_storage
    puts "Removed #{removed} redundant coverage history records"
    removed
  end
end
