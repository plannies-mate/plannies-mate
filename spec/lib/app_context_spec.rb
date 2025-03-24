# frozen_string_literal: true

require_relative '../spec_helper'
require_relative '../../app/lib/app_context'

RSpec.describe AppContext do
  let(:context) { described_class.new }
  let(:expected_views_dir) { File.expand_path('../../app/views', __dir__) }

  describe '#initialize' do
    it 'stores the views directory path' do
      expect(context.views_dir).to eq(expected_views_dir)
    end
  end

  describe '#number_with_delimiter' do
    it 'adds commas to large numbers' do
      expect(context.number_with_delimiter(1000)).to eq('1,000')
      expect(context.number_with_delimiter(1_000_000)).to eq('1,000,000')
    end

    it 'handles nil values' do
      expect(context.number_with_delimiter(nil)).to be_nil
    end

    it 'handles strings' do
      expect(context.number_with_delimiter('1000')).to eq('1,000')
    end
  end

  describe '#format_date' do
    it 'formats date strings' do
      expect(context.format_date('2023-01-15')).to eq('15 Jan 2023')
    end

    it 'handles nil values' do
      expect(context.format_date(nil)).to be_nil
    end

    it 'handles invalid dates' do
      expect(context.format_date('not a date')).to eq('not a date')
    end
  end

  describe '#status_class' do
    it 'returns status-warning for true' do
      expect(context.status_class(true)).to eq('status-warning')
    end

    it 'returns status-ok for false' do
      expect(context.status_class(false)).to eq('status-ok')
    end
  end

  describe '#render_partial' do
    it 'is defined' do
      expect(context).to respond_to(:render_partial)
    end
  end
end
