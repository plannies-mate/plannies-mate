# frozen_string_literal: true

require 'tilt'
require 'slim'

require_relative '../helpers/application_helper'
require_relative '../models/authority'
require_relative 'generator_base'

# Generates `site_dir/scrapers/#{morph_scraper.name}.html`
class ScraperGenerator
  extend GeneratorBase
  extend ApplicationHelper

  def self.generate(scraper)
    locals = {
      scraper: scraper,
      title: scraper.name,
    }

    locals[:output_file] =
      render_to_file('scraper', "scrapers/#{scraper.name}", locals)
    log "Generated scraper page for #{scraper.name}"
    locals
  end

  # Generate pages for all authorities
  def self.generate_all
    Scraper.all.each do |scraper|
      generate(scraper)
    end
    log 'Generated all scraper pages'
  end
end
