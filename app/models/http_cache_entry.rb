# frozen_string_literal: true

require_relative 'application_record'

# Model for tracking HTTP cache headers (ETag, Last-Modified) for URLs
#
# == Schema Information
#
# Table name: http_cache_entries
#
#  id                     :integer          not null, primary key
#  etag                   :string
#  last_modified_at       :datetime
#  last_not_modified_at   :datetime
#  last_other_response_at :datetime
#  last_success_at        :datetime
#  url                    :string           not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_http_cache_entries_on_url  (url) UNIQUE
#
class HttpCacheEntry < ApplicationRecord
  validates :url, presence: true, uniqueness: true

  # Find or create a cache entry for the given URL
  # @param url [String] The URL to find or create an entry for
  # @return [HttpCacheEntry] The found or created entry
  def self.for_url(url)
    find_or_create_by(url: url)
  end

  # Update the cache entry with headers from an HTTP response
  # @param response [Mechanize::Page] The HTTP response
  # @return [Boolean] Whether the entry was updated
  def update_from_response(response)
    changed = false

    # Extract ETag if present
    if response.header['etag'].present? && response.header['etag'] != etag
      self.etag = response.header['etag']
      changed = true
    end

    # Extract Last-Modified if present
    if response.header['last-modified'].present?
      begin
        last_mod = Time.parse(response.header['last-modified'])
        if last_mod && last_mod != last_modified_at
          self.last_modified_at = last_mod
          changed = true
        end
      rescue ArgumentError
        # Ignored
      end
    end

    case response.code
    when '200'
      self.last_success_at = Time.now
    when '304'
      self.last_not_modified_at = Time.now
    else
      self.last_other_response_at = Time.now
    end

    save!

    changed
  end

  # Build HTTP headers for conditional request
  # @return [Hash] The HTTP headers to use for a conditional request
  def conditional_headers
    headers = {}

    # Add If-None-Match header if we have an ETag
    headers['If-None-Match'] = etag if etag.present?

    # Add If-Modified-Since header if we have a Last-Modified date
    headers['If-Modified-Since'] = last_modified_at.httpdate if last_modified_at.present?

    headers
  end

  # Check if this cache entry is stale (older than 7 days)
  # @return [Boolean] Whether the entry is stale
  def stale?
    return true if last_success_at.nil?

    week_ago = Time.now - 7.days
    last_success_at <= week_ago
  end
end
