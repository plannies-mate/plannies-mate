# frozen_string_literal: true

require 'tilt'
require 'slim'
require_relative '../helpers/application_helper'
require_relative '../models/coverage_history'
require_relative 'generator_base'

# Generates `site_dir/coverage-history.html` with graph of authority coverage over time
class CoverageHistoryGenerator
  extend GeneratorBase
  extend ApplicationHelper

  def self.generate
    # Get all history records ordered by date
    histories = CoverageHistory.order(:recorded_on).to_a

    return nil if histories.empty?

    locals = {
      histories: histories,
      percentage_data: percentage_coverage_data(histories),
      recent: histories.last,
      authorities_data: authorities_coverage_data(histories),
    }

    locals[:output_file] = render_to_file('coverage_history', 'coverage-history', locals)
    log "Generated coverage history page with #{histories.size} data points"
    locals
  end

  def self.percentage_coverage_data(histories)
    # Format data for chart.js
    {
      labels: histories.map { |h| h.recorded_on.strftime('%Y-%m-%d') },
      datasets: [
        {
          label: 'Broken %Population',
          data: histories.map(&:broken_population_percentage),
          borderColor: '#FFCD00', # Australian gold
          backgroundColor: 'rgba(255, 205, 0, 0.1)',
          fill: true,
        },
        {
          label: 'Coverage %Population',
          data: histories.map(&:coverage_percentage),
          borderColor: '#00843D', # Australian green
          backgroundColor: 'rgba(0, 132, 61, 0.1)',
          fill: true,
        },
        {
          label: 'Broken+Coverage %Population',
          data: histories.map(&:total_population_percentage),
          borderColor: '#003D84',
          backgroundColor: 'rgba(0, 61, 132, 0.1)',
          # fill: true,
        },
      ],
    }
  end

  def self.authorities_coverage_data(histories)
    # Format data for chart.js
    {
      labels: histories.map { |h| h.recorded_on.strftime('%Y-%m-%d') },
      datasets: [
        {
          label: 'Broken Authorities',
          data: histories.map(&:broken_authority_count),
          borderColor: '#FFCD00', # Australian gold
          backgroundColor: 'rgba(255, 205, 0, 0.1)',
          # borderWidth: 1,
          fill: true,
        },
        {
          label: 'Working Authorities',
          data: histories.map(&:working_count),
          borderColor: '#00843D', # Australian green
          backgroundColor: 'rgba(0, 132, 61, 0.1)',
          # borderWidth: 1,
          fill: true,
        },
        {
          label: 'Total Authorities',
          data: histories.map(&:authority_count),
          borderColor: '#003D84',
          backgroundColor: 'rgba(0, 61, 132, 0.1)',
          # borderWidth: 1,
        },
      ],
    }
  end
end
