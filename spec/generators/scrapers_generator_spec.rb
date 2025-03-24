# frozen_string_literal: true

require 'spec_helper'
require_relative '../../app/generators/scrapers_generator'

RSpec.describe ScrapersGenerator do
  before do
    # Create site_dir if it doesn't exist
    FileUtils.mkdir_p(app_helpers.site_dir)
  end
  
  after do
    # Clean up test data and output
    FileUtils.rm_rf(app_helpers.site_dir)
  end

  describe '.generate' do
    it 'generates a scrapers index page' do
      # Call the actual generator
      result = described_class.generate
      
      # Check the output file exists
      expect(File.exist?(result[:output_file])).to be true
      
      # Check the result contains expected data
      expect(result).to include(:multi_scrapers)
      expect(result).to include(:custom_scrapers)
      expect(result).to include(:total_count)
    end
  end
end
