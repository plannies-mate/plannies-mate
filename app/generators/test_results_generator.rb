# frozen_string_literal: true

require 'tilt'
require 'slim'
require_relative '../helpers/application_helper'
require_relative '../models/test_result'
require_relative 'generator_base'

# Generates `site_dir/test_results.html` with the list of test results
class TestResultsGenerator
  extend GeneratorBase
  extend ApplicationHelper

  def self.generate
    # Get all test results ordered by creation date (newest first)
    test_results = TestResult.order(:name).to_a

    # Prepare data for the template
    locals = {
      test_results: test_results,
      title: 'Test Results',
    }

    locals[:output_file] = render_to_file('test_results', 'test_results', locals)
    log "Generated test results page with #{test_results.size} test results"
    locals
  end
end
