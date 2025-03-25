# frozen_string_literal: true

require_relative '../spec_helper'
require_relative '../../app/importers/issues_importer'

RSpec.describe IssuesImporter do
  before do
    @importer = described_class.new
  end

  context 'importing from scratch' do
    before do
      FixtureHelper.clear_database
    end

    it 'imports authorities and scrapers', vcr: { cassette_name: cassette_name('import_issues_from_scratch') } do
      @importer.import

      count = Issue.count
      expect(count).to be > 100
    end
  end
  
  context 'handling null objects' do
    # Separate context to avoid conflicts with existing setup
    let(:importer) { described_class.new }
    
    describe '#import_user' do
      it 'returns nil when user is nil' do
        expect(importer.import_user(nil)).to be_nil
      end
    end
    
    describe '#import_label' do
      it 'returns nil when label is nil' do
        expect(importer.import_label(nil)).to be_nil
      end
    end
  end
end
