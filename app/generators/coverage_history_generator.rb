# frozen_string_literal: true

require 'tilt'
require 'slim'
require_relative '../helpers/application_helper'
require_relative '../models/coverage_history'
require_relative 'generator_base'

# Generates `site_dir/coverage_history.html` with graph of authority coverage over time
class CoverageHistoryGenerator
  extend GeneratorBase
  extend ApplicationHelper

  def self.generate
    # Get all history records ordered by date
    histories = CoverageHistory.order(:recorded_on).to_a

    return nil if histories.empty?

    # Prepare chart data
    chart_data = prepare_chart_data(histories)
    datasets = [
      {
        label: 'Broken Population',
        data: histories.map(&:broken_population).to_json,
        backgroundColor: 'rgba(54, 162, 235, 0.5)',
        borderColor: 'rgba(54, 162, 235, 1)',
        borderWidth: 1,
      },
      {
        label: 'Total Population',
        data: histories.map(&:total_population).to_json,
        backgroundColor: 'rgba(75, 192, 192, 0.5)',
        borderColor: 'rgba(75, 192, 192, 1)',
        borderWidth: 1,
      },
    ]

    labels = histories.map { |h| h.recorded_on.strftime('%Y-%m-%d') }
    # Render the template with the data
    locals = {
      histories: histories,
      chart_data: chart_data,
      recent: histories.last,
      datasets: datasets,
      labels: labels,
    }

    locals[:output_file] = render_to_file('coverage_history', 'coverage-history', locals)
    log "Generated coverage history page with #{histories.size} data points"
    locals
  end

  def self.prepare_chart_data(histories)
    # Format data for chart.js
    {
      labels: histories.map { |h| h.recorded_on.strftime('%Y-%m-%d') },
      datasets: [
        {
          label: 'Working Authorities %',
          data: histories.map { |h| (100 - h.broken_authority_percentage).round(1) },
          borderColor: '#00843D', # Australian green
          backgroundColor: 'rgba(0, 132, 61, 0.1)',
          fill: true,
        },
        {
          label: 'Population Coverage %',
          data: histories.map(&:coverage_percentage),
          borderColor: '#FFCD00', # Australian gold
          backgroundColor: 'rgba(255, 205, 0, 0.1)',
          fill: true,
        },
      ],
    }.to_json
  end
end
