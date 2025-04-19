# frozen_string_literal: true

require 'mechanize'
require 'json'
require 'fileutils'
require_relative '../helpers/application_helper'
require_relative 'scraper_base'

# Class to fetch and parse detailed information for a single authority
class AuthorityStatsFetcher
  extend ApplicationHelper
  extend ScraperBase

  BASE_URL = 'https://www.planningalerts.org.au/authorities/'

  def initialize(agent = nil)
    @agent = agent || self.class.create_agent
    @fetched = []
  end

  # Returns a hash of the details or nil
  def fetch(short_name, agent: nil)
    @fetched << short_name
    raise(ArgumentError, 'Must supply short_name') if short_name.blank?

    url = "#{BASE_URL}#{short_name}"

    page = self.class.fetch_page(url, agent: agent)
    stats = parse_stats(page, short_name)

    self.class.log "Fetched stats for #{short_name}"
    stats
  end

  private

  def parse_stats(page, short_name)
    stats = { 'short_name' => short_name }

    # Find the applications section
    apps_section = page.search('section.py-12').detect do |section|
      h2_text = section.at('h2')&.text
      h2_text&.strip&.include?('Applications collected')
    end
    return stats.merge('error' => 'Could not find applications section') unless apps_section

    error_p = apps_section.at('p.mt-8.text-xl.text-navy')
    if error_p&.text&.include?('something might be wrong')
      stats['warning'] = true
      # Extract the "last received" text if present
      last_received_match = error_p.text.match(/last new application was received ([^.]+)\./)
      stats['last_received'] = time_ago_to_date(last_received_match[1]) if last_received_match
    end

    # Extract counts from table
    apps_section.search('tr').each do |row|
      # Extract the number from the first cell
      count_cell = row.at('td')
      next unless count_cell

      count = self.class.extract_number(count_cell.text)

      # Extract the label from the second cell
      label_cell = row.at('th')
      next unless label_cell

      label_text = self.class.extract_text(label_cell).downcase

      if label_text.include?('in the last week')
        stats['week_count'] = count
      elsif label_text.include?('in the last month')
        stats['month_count'] = count
      elsif (added_match = label_text.match(/since ([^(]+).*when this authority was first added/))
        stats['total_count'] = count
        stats['added_on'] = added_match[1].strip
      elsif label_text.include?('median') && label_text.include?('per week')
        stats['median_per_week'] = count
      end
    end
    stats
  end

  # Convert text description of time passed (e.g., "over 2 years ago") to an estimated date
  # @param time_text [String] text description like "2 months ago"
  # @return [Date] estimated date
  def time_ago_to_date(time_text)
    return Date.today if time_text.blank?

    # Clean up the text and remove "ago"
    text = time_text.downcase.sub(/\s+ago\z/, '').sub(/\Aabout\s+/, '')

    multiplier = 1.0

    value = if text =~ /(\d+)/
              ::Regexp.last_match(1).to_f
            else
              1.0 # Default if no number (e.g., "about a month")
            end

    # Apply multipliers for different time units
    if text.include?('year')
      multiplier = 365.0
    elsif text.include?('month')
      multiplier = 365.0 / 12.0
    elsif text.include?('day')
      multiplier = 1.0 # Approximate
    elsif text.include?('week')
      multiplier = 7.0 # Approximate
    end

    # Apply modifiers
    if text.include?('almost')
      value -= 0.25
    elsif text.include?('over') || text.include?('more than')
      value += 0.25
    end

    # Calculate final value
    Date.today - (value * multiplier).round
  end
end
