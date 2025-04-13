# frozen_string_literal: true

require 'spec_helper'
require_relative '../../app/generators/coverage_history_generator'

RSpec.describe CoverageHistoryGenerator do
  before do
    # Create site_dir if it doesn't exist
    FileUtils.mkdir_p(app_helpers.site_dir)
  end

  after do
    # Clean up test data and output
    FileUtils.rm_rf(app_helpers.site_dir)
  end

  describe '.generate' do
    context 'when history data exists' do
      it 'generates a coverage history page with chart data' do
        result = described_class.generate

        expect(File.exist?(result[:output_file])).to be true

        expect(result).to include(:histories)
        expect(result).to include(:chart_data)
        expect(result).to include(:recent)
      end
    end

    context 'when no history data exists' do
      it 'returns nil' do
        # Mock an empty result to simulate no history data
        allow(CoverageHistory).to receive(:order).and_return([])

        result = described_class.generate
        expect(result).to be_nil
      end
    end
  end
end
