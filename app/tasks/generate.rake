# frozen_string_literal: true

require_relative '../generators/authorities_generator'
require_relative '../generators/authority_generator'
require_relative '../generators/scrapers_generator'
require_relative '../generators/scraper_generator'

namespace :generate do
  desc 'Generate all reports'
  task all: %i[singleton roundup:flag_updating content coverage_history github roundup:flag_finished] do
    puts 'All reports generated successfully'
  end

  desc 'Generate reports that are affected by github import'
  task github: %i[singleton roundup:flag_updating authorities authority_pages scrapers scraper_pages pull_requests
                  roundup:flag_finished] do
    puts 'All reports generated successfully'
  end

  desc 'Generate static content'
  task :content do
    ContentGenerator.generate_public
    ContentGenerator.generate_contents
  end

  desc 'Generate authorities existing and new index page'
  task :authorities do
    AuthoritiesGenerator.generate_existing
    AuthoritiesGenerator.generate_delisted
    AuthoritiesGenerator.generate_orphaned
    AuthoritiesGenerator.generate_extra_councils
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

  # Move to generate.rake
  desc 'Generate static pages for pull requests'
  task pull_requests: :singleton do
    puts 'Generating static pages for pull requests...'

    index_result = PullRequestsGenerator.generate

    if index_result
      puts "Generated pull requests index page with #{index_result[:pull_requests].size} pull requests"
    else
      puts 'No pull requests found to generate pages'
    end
  end
end
