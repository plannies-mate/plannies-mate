# frozen_string_literal: true

require 'mechanize'
require 'json'
require 'fileutils'
require_relative '../helpers/application_helper'
require_relative 'scraper_base'

# Class to scrape authority list from PlanningAlerts website
class AuthoritiesFetcher
  extend ApplicationHelper
  extend ScraperBase

  AUTHORITIES_URL = 'https://www.planningalerts.org.au/authorities'

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
  #       "url": "https://www.planningalerts.org.au/authorities/albury",
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

      authority_cell = cells[1]
      authority_link = authority_cell.at('a')
      next unless authority_link

      record['state'] = self.class.extract_text(cells[0])
      record['name'] = self.class.extract_text(authority_link)
      record['url'] = authority_link['href']
      record['short_name'] = record['url'].split('/').last
      record['possibly_broken'] = !authority_cell.at('div.bg-yellow').nil?
      record['population'] = self.class.extract_number(cells[2].text)
      authorities << record
    end

    authorities
  end
end
