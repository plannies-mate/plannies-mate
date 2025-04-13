# frozen_string_literal: true

# Imports Authorities to DB
class AuthoritiesImporter
  attr_reader :count, :changed

  def initialize
    @list_fetcher = AuthoritiesFetcher.new
    @details_fetcher = AuthorityDetailsFetcher.new
    @stats_fetcher = AuthorityStatsFetcher.new
    @count = @changed = @orphaned = 0
  end

  def import(force: false)
    @count = @changed = 0
    list = @list_fetcher.fetch(force: force)
    orphaned_ids = Authority.where(delisted_on: nil).pluck(:id)
    if list
      list.each do |entry|
        short_name = entry['short_name']
        next if short_name.blank?

        authority = Authority.find_or_initialize_by(short_name: short_name)
        authority.delisted_on = nil
        authority.assign_relevant_attributes(entry)
        import_stats_and_details(authority)
        orphaned_ids -= [authority.id]
      end
      orphaned_ids.each do |id|
        Authority.find(id).update!(delisted_on: Date.today)
      end
      @orphaned = orphaned_ids.count
    else
      puts 'Authorities list has not changed, checking details'
      Authority.active.each do |authority|
        import_stats_and_details(authority, force: force)
      end
    end

    authority_count = Authority.active.count
    broken_count = Authority.active.broken.count
    total_pop = Authority.active.sum(&:population)
    broken_pop = Authority.active.broken.sum(&:population)

    coverage_history = CoverageHistory.find_or_initialize_by(recorded_on: Date.today)
    coverage_history.update!(
      authority_count: authority_count,
      broken_authority_count: broken_count,
      total_population: total_pop,
      broken_population: broken_pop
    )

    puts "Updated #{@changed} of #{@count} authorities (#{@orphaned} orphaned)"
  end

  private

  def import_stats_and_details(authority, force: false)
    @count += 1
    short_name = authority.short_name
    details = @details_fetcher.fetch(short_name, force: force)
    if details
      authority.assign_relevant_attributes details

      scraper_name = details['scraper_name']
      this_scraper = Scraper.find_by(name: scraper_name)
      if this_scraper.nil?
        this_scraper = Scraper.create!(name: scraper_name)
        puts "Created newly found scraper: #{scraper_name}"
      end
      authority.scraper = this_scraper
    end
    stats = @stats_fetcher.fetch(short_name, force: force)
    authority.assign_relevant_attributes stats
    return unless authority.changed?

    @changed += 1
    authority.save!
  end
end
