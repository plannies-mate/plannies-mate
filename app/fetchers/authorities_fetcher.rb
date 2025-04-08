# frozen_string_literal: true

require 'mechanize'
require 'json'
require 'fileutils'
require_relative '../helpers/application_helper'
require_relative '../helpers/html_helper'
require_relative 'scraper_base'

# Class to scrape authority list from PlanningAlerts website
class AuthoritiesFetcher
  extend ApplicationHelper
  extend HtmlHelper
  extend ScraperBase

  AUTHORITIES_URL = 'https://www.planningalerts.org.au/authorities'

  STATES = %w[WA NSW VIC QLD SA TAS ACT NT]

  def initialize(agent = nil)
    @agent = agent || self.class.create_agent
  end

  # Return the list of all authorities from main planning alerts page
  #
  # @example:
  #   [
  #     {
  #       "state": "NSW",
  #       "name": "Albury City Council",
  #       "short_name": "albury",
  #       "possibly_broken": true,
  #       "population": 56093
  #     },
  #     ...
  #   ]
  def fetch(force: false, agent: nil, url: AUTHORITIES_URL)
    self.class.log "Fetching authority data from #{url}"

    page = self.class.fetch_page_with_cache(url, agent: agent, force: force)

    return nil if page.nil?

    authorities = parse_authorities(page)
    self.class.log "Fetched #{authorities.size} authorities"
    authorities
  end

  private

  def parse_authorities(page)
    authorities = []
    rows = page.search('table tbody tr')

    rows.each do |row|
      record = {}
      cells = row.search('td')
      next if cells.empty? || cells.length < 3

      cells[1]
      authority_link = row.at('a')
      next unless authority_link

      state = self.class.extract_text(cells[0])
      record['state'] = state if STATES.include?(state)
      record['name'] = self.class.extract_text(authority_link)
      record['short_name'] = self.class.last_url_segment authority_link['href']
      record['possibly_broken'] = self.class.extract_text(row).downcase.include?('possibly broken')
      record['population'] = self.class.extract_number(cells[2]&.text)
      authorities << record
    end

    authorities
  end
end
