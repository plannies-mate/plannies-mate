# frozen_string_literal: true

# Imports TestResults to DB
class TestResultsImporter
  attr_reader :count, :changed

  def initialize
    @list_fetcher = TestResultsFetcher.new
    @details_fetcher = TestResultDetailsFetcher.new
    @db_fetcher = TestResultsDbFetcher.new
    @count = @changed = @orphaned = 0
  end

  def import
    @count = @changed = @orphaned = 0
    list = @list_fetcher.fetch
    TestResult.pluck(:commit_sha)
    list.each do |entry|
      name = entry['full_name']
      next if name.blank?

      test_result = TestResult.find_or_initialize_by(name: name)
      test_result.delisted_on = nil
      test_result.assign_relevant_attributes(entry)
      import_stats_and_details(test_result)
      orphaned_ids - [test_result.id]
    end
    orphaned_ids.each do |id|
      TestResult.find(id).update!(delisted_on: Date.today)
    end
    @orphaned = orphaned_ids.count

    test_result_count = TestResult.active.count
    broken_count = TestResult.active.broken.count
    total_pop = TestResult.active.sum(&:population)
    broken_pop = TestResult.active.broken.sum(&:population)

    coverage_history = CoverageHistory.find_or_initialize_by(recorded_on: Date.today)
    coverage_history.update!(
      test_result_count: test_result_count,
      broken_test_result_count: broken_count,
      total_population: total_pop,
      broken_population: broken_pop
    )

    puts "Updated #{@changed} of #{@count} testResults (#{@orphaned} orphaned)"
  end

  private

  def import_stats_and_details(test_result, force: false)
    @count += 1
    name = test_result.name
    details = @details_fetcher.fetch(name, force: force)
    if details
      test_result.assign_relevant_attributes details

      scraper_name = details['scraper_name']
      this_scraper = Scraper.find_by(name: scraper_name)
      if this_scraper.nil?
        this_scraper = Scraper.create!(name: scraper_name)
        puts "Created newly found scraper: #{scraper_name}"
      end
      test_result.scraper = this_scraper
    end
    stats = @db_fetcher.fetch(name, force: force)
    test_result.assign_relevant_attributes stats
    return unless test_result.changed?

    @changed += 1
    test_result.save!
  end
end
