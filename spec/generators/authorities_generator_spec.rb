# frozen_string_literal: true

require 'spec_helper'
require_relative '../../app/generators/authorities_generator'

RSpec.describe AuthoritiesGenerator do
  before do
    # Create site_dir if it doesn't exist
    FileUtils.mkdir_p(app_helpers.site_dir)
  end

  after do
    # Clean up test data and output
    FileUtils.rm_rf(app_helpers.site_dir)
  end

  describe '.generate_existing' do
    it 'generates an authorities index page' do
      # Call the actual generator
      result = described_class.generate_existing

      # Check the output file exists
      expect(File.exist?(result[:output_file])).to be true

      # Check the result contains expected data
      expect(result).to include(:authorities)
    end
  end

  describe '.generate_delisted' do
    it 'generates an authorities delisted index page' do
      # Call the actual generator
      result = described_class.generate_delisted

      # Check the output file exists
      expect(File.exist?(result[:output_file])).to be true

      # Check the result contains expected data
      expect(result).to include(:authorities)
    end
  end

  describe '.generate_orphaned' do
    it 'generates an orphaned issues index page' do
      # Call the actual generator
      result = described_class.generate_orphaned

      # Check the output file exists
      expect(File.exist?(result[:output_file])).to be true

      # Check the result contains expected data
      expect(result).to include(:issues)
    end
  end

  describe '.generate_extra_councils' do
    it 'generates extra councils index page' do
      # Call the actual generator
      result = described_class.generate_extra_councils

      # Check the output file exists
      expect(File.exist?(result[:output_file])).to be true

      # Check the result contains expected data
      expect(result).to include(:councils_by_state)
      expect(result).to include(:states)
      expect(result).to include(:title)
      expected = { 'name' => 'Local Government Directory',
                   'url' => 'https://www.olg.nsw.gov.au/public/local-government-directory/', }
      expect(result[:states]['NSW']).to eq(expected)
      expect(result[:councils_by_state]['NSW']).to be_a(Array)
      expect(result[:councils_by_state]['NSW']).not_to be_empty
    end
  end
end
