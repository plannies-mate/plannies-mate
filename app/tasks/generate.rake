# frozen_string_literal: true

require_relative '../generators/authorities_generator'
require_relative '../generators/authority_generator'
require_relative '../generators/scrapers_generator'
require_relative '../generators/scraper_generator'

namespace :generate do
  desc 'Generate all reports'
  task all: %i[singleton authorities authority_pages scrapers scraper_pages coverage_history] do
    puts 'All reports generated successfully'
  end

  desc 'Generate static content'
  task :content do
    ContentGenerator.generate_public
    ContentGenerator.generate_contents
  end

  desc 'Generate authorities index page'
  task :authorities do
    AuthoritiesGenerator.generate
  end

  desc 'Generate individual authority pages'
  task :authority_pages do
    AuthorityGenerator.generate_all
  end

  desc 'Generate scrapers index page'
  task :scrapers do
    ScrapersGenerator.generate
  end

  desc 'Generate individual scraper pages'
  task :scraper_pages do
    ScraperGenerator.generate_all
  end

  desc 'Generate coverage history report'
  task :coverage_history do
    CoverageHistoryGenerator.generate
  end
end
