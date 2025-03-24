# frozen_string_literal: true

require 'spec_helper'
require_relative '../../app/generators/scraper_generator'

RSpec.describe ScraperGenerator do
  before do
    # Create site_dir if it doesn't exist
    FileUtils.mkdir_p(app_helpers.site_dir)
  end
  
  after do
    # Clean up test data and output
    FileUtils.rm_rf(app_helpers.site_dir)
  end

  describe '.generate' do
    it 'generates a page for a single scraper' do
      # Use a fixture scraper
      scraper = Fixture.find(Scraper, :multiple_atdis)
      
      # Call the actual generator
      result = described_class.generate(scraper)
      
      # Check the output file exists
      expect(File.exist?(result[:output_file])).to be true
      
      # Check the result contains expected data
      expect(result[:scraper]).to eq(scraper)
      expect(result[:title]).to eq(scraper.name)
    end
  end
  
  describe '.generate_all' do
    it 'generates pages for all scrapers' do
      # Just verify it runs without errors
      expect { described_class.generate_all }.not_to raise_error
    end
  end
end
