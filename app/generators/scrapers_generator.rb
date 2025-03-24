# frozen_string_literal: true

require 'tilt'
require 'slim'

require_relative '../helpers/application_helper'
require_relative '../models/authority'
require_relative 'generator_base'

# Generates `site_dir/scrapers.html`
class ScrapersGenerator
  extend GeneratorBase
  extend ApplicationHelper

  # Generate file and returns locals used for views
  def self.generate
    my_locals = locals

    my_locals[:output_file] =
      render_to_file('scrapers', 'scrapers', my_locals)
    log "Generated scrapers index page with #{my_locals[:total_count]} scrapers"
    my_locals
  end

  # Returns a locals hash to use with view
  def self.locals
    scrapers = Scraper.all.sort_by(&:to_param)

    # Group scrapers by type
    multi_scrapers = scrapers.select { |s| s.authorities.size > 1 }
                             .sort_by { |s| [-s.authorities.size, s.to_param] }
    custom_scrapers = scrapers.select { |s| s.authorities.size == 1 }
    orphaned_scrapers = scrapers.select { |s| s.authorities.empty? }

    {
      multi_scrapers: multi_scrapers,
      custom_scrapers: custom_scrapers,
      orphaned_scrapers: orphaned_scrapers,
      total_count: scrapers.size,
      title: 'Scrapers',
    }
  end
end
