# frozen_string_literal: true

# Imports Authorities to DB
class AuthoritiesImporter
  attr_reader :count, :changed

  def initialize
    @list_fetcher = AuthoritiesFetcher.new
    @details_fetcher = AuthorityDetailsFetcher.new
    @stats_fetcher = AuthorityStatsFetcher.new
    @count = @changed = 0
  end

  def import
    @count = @changed = 0
    list = @list_fetcher.fetch
    if list
      list.each do |entry|
        short_name = entry['short_name']
        next if short_name.blank?

        authority = Authority.find_by_short_name(short_name) || Authority.new(short_name: short_name)
        authority.assign_relevant_attributes(entry)
        import_stats_and_details(authority)
      end
    else
      puts 'Authorities list has not changed, checking details'
      Authority.all.each do |authority|
        import_stats_and_details(authority)
      end
    end
    puts "Updated #{@changed} of #{@count} authorities"
  end

  private

  def import_stats_and_details(authority)
    @count += 1
    short_name = authority.short_name
    authority.assign_relevant_attributes @details_fetcher.fetch(short_name)
    authority.assign_relevant_attributes @stats_fetcher.fetch(short_name)
    return unless authority.changed?

    @changed += 1
    authority.save!
  end
end
