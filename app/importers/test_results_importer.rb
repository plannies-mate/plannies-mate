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
    # TestResult.pluck(:commit_sha)
    list.each do |entry|
      name = entry['name']
      next if name.blank?

      test_result = TestResult.find_or_initialize_by(name: name)
      extra_details = @details_fetcher.fetch(name)
      if extra_details.nil?
        test_result.destroy
        next
      end

      if extra_details['has_authority_label']
        counts = @db_fetcher.fetch_authority_label_count(name)
        extra_details['counts'] = counts
        extra_details['successful_authorities'] = counts.keys.join(',') unless extra_details['successful_authorities']
      else
        extra_details['count'] = @db_fetcher.fetch_count(name)
      end

      entry.merge!(extra_details)

      test_result.assign_relevant_attributes(entry)
      unless test_result.scraper
        puts "Unable to match scraper to test_results for #{name} - ignored!"
        next
      end

      import_authority_test_results(test_result, entry)
      test_result.save!
    end

    puts "Updated #{@changed} of #{@count} testResults (#{@orphaned} orphaned)"
  end

  private

  def import_authority_test_results(test_result, entry)
    missing_good = entry['successful_authorities'].split(',')
    missing_bad = (entry['failed_authorities']&.split(',') || []) + (entry['interrupted_authorities']&.split(',') || [])
    orphaned_atr_ids = test_result.authority_test_results.pluck(:id)
    single = test_result.scraper.authorities.count == 1
    test_result.scraper.authorities.each do |authority|
      atr = test_result.authority_test_results.find_or_initialize_by(authority_id: authority.id)
      orphaned_atr_ids.delete(atr.id)
      atr.authority_label = authority.short_name
      atr.failed = if missing_good.delete(atr.authority_label)
                     false
                   elsif missing_bad.delete(atr.authority_label)
                     true
                   elsif single
                     !entry['count']&.positive
                   else
                     puts "WARNING: Failed to match test result(#{test_result.name}).authority_label" \
                            "(#{atr.authority_label}) in remaining good(#{missing_good.inspect}) or " \
                            "bad(#{missing_bad.inspect}) lists!"
                     false
                   end

      # TODO: update atr.error_message from latest scrape_log entry
      atr.record_count = if single
                           entry['count']
                         else
                           entry['counts'][atr.authority_label]
                         end
    end
    if orphaned_atr_ids.any?
      puts "NOTE: Removed #{orphaned_atr_ids.size} orphaned AuthorityTestRecord records (not tested?)"
      AuthorityTestResult.where(id: orphaned_atr_ids).delete_all
    end
    puts "WARNING: Unable to match successful_authorities: #{missing_good.inspect}" if missing_good.any?
    puts "WARNING: Unable to match failed/interrupted_authorities: #{missing_bad.inspect}" if missing_bad.any?
  end
end
