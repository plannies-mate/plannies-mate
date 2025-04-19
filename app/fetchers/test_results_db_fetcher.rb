# frozen_string_literal: true

require 'mechanize'
require 'json'
require 'uri'
require_relative '../helpers/application_helper'
require_relative 'scraper_base'

# Class to fetch test result data from morph.io API
class TestResultsDbFetcher
  extend ApplicationHelper
  extend ScraperBase

  def initialize(api_key: nil, agent: nil)
    @api_key = api_key || ENV.fetch('MORPH_API_KEY') { raise 'Must supply MORPH_API_KEY env variable' }
    @agent = agent || self.class.create_agent
  end

  # Fetch authority label counts from the data table from the last week
  #
  # @param name [String] The name of the test result (repository) on morph.io
  # @return [Hash<String, Integer>] Hash of authority_labels and associated count of records in last 7 days
  def fetch_authority_label_count(name)
    since_db = "date('now','-7 days')"
    query = "SELECT authority_label, count(*) AS count FROM data WHERE date_scraped >= #{since_db} GROUP BY 1"
    call_api(name, query: query)
  end

  # Fetch record count from the data table from the last week
  #
  # @param name [String] The name of the test result (repository) on morph.io
  # @return [Integer] count of records in last 7 days
  def fetch_count(name)
    since_db = "date('now','-7 days')"
    query = "SELECT \"all\" as authority_label, count(*) AS count FROM data WHERE date_scraped >= #{since_db}"
    call_api(name, query: query)['all']
  end

  private

  def call_api(name, query:)
    raise ArgumentError, 'Requires a name' if name.blank?

    params = {
      key: @api_key,
      query: query,
    }
    url = "#{Constants::MORPH_URL}/#{Constants::MY_GITHUB_NAME}/#{name}/data.json?#{URI.encode_www_form(params)}"
    page = self.class.fetch_page(url, agent: @agent)
    return {} unless page

    result = {}
    JSON.parse(page.body).each do |data|
      result[data['authority_label']] = data['count']
    end
    result
  end
end
