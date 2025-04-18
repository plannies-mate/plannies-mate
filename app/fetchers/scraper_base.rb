# frozen_string_literal: true

require 'mechanize'
require 'json'
require 'fileutils'
require 'time'

# Module providing common functionality for web scrapers
# use `extend ApplicationHelper` so everything (except InstanceMethods) become class methods
module ScraperBase
  # Create a standardized Mechanize agent
  def create_agent
    agent = Mechanize.new
    agent.user_agent = 'Plannies-Mate/1.0'
    agent.robots = :all
    agent.history.max_size = 1
    agent
  end

  # Extract text from a node, stripping off leading and trailing white space and
  # condensing white space in the middle to single spaces
  def extract_text(node)
    node.text.strip.gsub(/\s\s+/, ' ') if node&.text
  end

  # Extract an integer number from text, ignoring non-digit characters except periods (.)
  def extract_number(text)
    text&.gsub(/[^\d.]+/, '')&.to_i
  end

  # Instance Methods to be included
  module InstanceMethods
    # Fetch a page with conditional GET using HTTP cache entries
    # @param url [String] URL to fetch
    # @param agent [Mechanize] Mechanize Agent
    # @param force [Boolean, :historical] Force page to be retrieved (:historical does not save cache info)
    # @param cache_key [String, nil] Optional key for cache
    # @return [Mechanize::Page, nil] The page if modified, nil if not modified
    def fetch_page_with_cache(url, agent: nil, force: false, cache_key: nil)
      agent ||= create_agent

      # Get the cache entry for this URL
      cache_entry = HttpCacheEntry.for_url(cache_key || url)

      # Don't use cached data if forced or the entry is stale
      headers = {}
      headers = cache_entry.conditional_headers unless force? || force || cache_entry.stale?

      begin
        started = Time.now
        page = agent.get(url, [], nil, headers)
        took = Time.now - started

        log "DEBUG: Delaying #{(took * 2).round(3)}s for #{url}" if debug?
        sleep(took) unless test?

        http_code = page.code.to_i
        if http_code == 304
          log "NOTE: Remote content unchanged for #{url}"
          nil
        elsif ![200, 203].include?(http_code)
          raise("ERROR: Unaccepted response code: #{http_code} for #{url}")
        elsif page.body.empty?
          raise("ERROR: Empty response for #{url}")
        else
          # Update the cache entry with the new response
          cache_entry.update_from_response(page) unless force == :historical
          page
        end
      rescue StandardError => e
        log "ERROR: Failed to fetch #{url}: #{e.message}"
        raise e
      end
    end
  end

  send :include, InstanceMethods
end
