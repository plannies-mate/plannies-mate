# frozen_string_literal: true

require 'mechanize'
require 'json'
require 'fileutils'
require_relative '../helpers/application_helper'
require_relative 'scraper_base'

# Class to fetch and parse detailed information for a single authority
class AuthorityDetailsFetcher
  extend ApplicationHelper
  extend ScraperBase

  BASE_URL = 'https://www.planningalerts.org.au/authorities/'

  def initialize(agent = nil)
    @agent = agent || self.class.create_agent
    @fetched = []
  end

  # Returns find for an authority
  #
  # @example:
  #   {
  #     "short_name": "banyule",
  #     "morph_url": "https://morph.io/planningalerts-scrapers/multiple_civica",
  #     "github_url": "https://github.com/planningalerts-scrapers/multiple_civica",
  #     "last_log": "0 applications found for Bayside City Council (Victoria), VIC with date from 2025-03-11\nTook 0 s to import applications from Bayside City Council (Victoria), VIC",
  #     "total_count": 0,
  #     "import_time": "0 s"
  #   }
  def fetch(short_name, agent: nil, force: false)
    @fetched << short_name
    raise(ArgumentError, 'Must supply short_name') if short_name.blank?

    url = "#{BASE_URL}#{short_name}/under_the_hood"

    page = self.class.fetch_page_with_cache(url, agent: agent, force: force)

    return nil if page.nil?

    details = parse_details(page, short_name)

    self.class.log "Fetched details for #{short_name}"
    details
  end

  private

  def parse_details(page, short_name)
    details = { 'short_name' => short_name }

    # Extract morph.io URL - look for 'Watch the scraper' link
    page.links.each do |link|
      if link.text.strip.include?('Watch the scraper')
        details['morph_url'] = link.href
      elsif link.text.strip.include?('Fork the scraper on Github')
        details['github_url'] = link.href
      end
    end

    # Extract the recent import logs
    import_section = page.search('section#import')
    if import_section&.any?
      # Look for pre tag with logs
      pre_text = (import_section.at('pre')&.text || '').to_s.strip
      unless pre_text.empty?
        details['last_log'] = pre_text

        # Additionally extract some useful data from the log
        if (match = pre_text.match(/(\d+) applications found/))
          details['total_count'] = match[1].to_i
        end

        if (match = pre_text.match(/Took (\d+(\.\d+)? \w*) to import/))
          details['import_time'] = match[1]
        end
      end
    end

    raise("MISSING morph_url FROM: #{details.inspect}") if details['morph_url'].blank?
    raise("MISSING github_url FROM: #{details.inspect}") if details['github_url'].blank?

    details
  end
end
