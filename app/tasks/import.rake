# frozen_string_literal: true

require_relative '../importers/authorities_importer'
require_relative '../importers/issues_importer'

namespace :import do
  desc 'Import all information from remote sites'
  task all: %i[singleton authorities issues] do
    puts 'Finished'
  end

  desc 'Import planning authority list from PlanningAlerts'
  task authorities: :singleton do
    authorities_scraper = AuthoritiesImporter.new
    authorities_scraper.import
  end

  desc 'Import Open Issues'
  task issues: :singleton do
    fetcher = IssuesImporter.new
    fetcher.import
  end
end
