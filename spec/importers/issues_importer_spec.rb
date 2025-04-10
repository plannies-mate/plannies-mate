# frozen_string_literal: true

require_relative '../spec_helper'
require_relative '../../app/importers/issues_importer'

RSpec.describe IssuesImporter do
  context 'importing from scratch' do
    before do
      FixtureHelper.clear_database
    end

    it 'imports authorities and scrapers', vcr: { cassette_name: cassette_name('import_issues_from_scratch') } do
      importer = described_class.new
      importer.import

      count = Issue.count
      expect(count).to be > 100
    end
  end

  context 'handling null objects' do
    describe '#import_user' do
      it 'returns nil when user is nil', vcr: { cassette_name: cassette_name('import_nil_user') } do
        importer = described_class.new
        expect(importer.import_user(nil)).to be_nil
      end
    end

    describe '#import_label' do
      it 'returns nil when label is nil', vcr: { cassette_name: cassette_name('import_nil_label') } do
        importer = described_class.new
        expect(importer.import_label(nil)).to be_nil
      end
    end
  end
end
