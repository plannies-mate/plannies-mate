# frozen_string_literal: true

# Imports TestResults to DB
class TestResultsImporter
  attr_reader :count, :changed

  def initialize
    @list_fetcher = TestResultsFetcher.new
    @details_fetcher = TestResultDetailsFetcher.new
    @stats_fetcher = TestResultStatsFetcher.new
    @count = @changed = @orphaned = 0
  end

  def import(force: false)
    @count = @changed = 0
    list = @list_fetcher.fetch(force: force)
    orphaned_ids = TestResult.where(delisted_on: nil).pluck(:id)
    if list
      list.each do |entry|
        short_name = entry['short_name']
        next if short_name.blank?

        test_result = TestResult.find_or_initialize_by(short_name: short_name)
        test_result.delisted_on = nil
        test_result.assign_relevant_attributes(entry)
        import_stats_and_details(test_result)
        orphaned_ids -= [test_result.id]
      end
      orphaned_ids.each do |id|
        TestResult.find(id).update!(delisted_on: Date.today)
      end
      @orphaned = orphaned_ids.count
    else
      puts 'TestResults list has not changed, checking details'
      TestResult.active.each do |test_result|
        import_stats_and_details(test_result, force: force)
      end
    end

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
    short_name = test_result.short_name
    details = @details_fetcher.fetch(short_name, force: force)
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
    stats = @stats_fetcher.fetch(short_name, force: force)
    test_result.assign_relevant_attributes stats
    return unless test_result.changed?

    @changed += 1
    test_result.save!
  end
end
