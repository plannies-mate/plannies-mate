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
    
    # Render the template with the data
    locals = {
      histories: histories,
      chart_data: chart_data,
      recent: histories.last
    }
    
    locals[:output_file] = render_to_file('coverage_history', 'coverage_history', locals)
    log "Generated coverage history page with #{histories.size} data points"
    locals
  end
  
  private
  
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
          fill: true
        },
        {
          label: 'Population Coverage %',
          data: histories.map { |h| h.coverage_percentage },
          borderColor: '#FFCD00', # Australian gold
          backgroundColor: 'rgba(255, 205, 0, 0.1)',
          fill: true
        }
      ]
    }.to_json
  end
end
