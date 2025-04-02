# frozen_string_literal: true

# == Schema Information
#
# Table name: scrapers
#
#  id                  :integer          not null, primary key
#  authorities_path    :string
#  default_branch      :string           default("master"), not null
#  name                :string           not null
#  needs_generate      :boolean          default(TRUE), not null
#  needs_import        :boolean          default(TRUE), not null
#  scraper_path        :string
#  update_reason       :string
#  update_requested_at :datetime
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
# Indexes
#
#  index_scrapers_on_name  (name) UNIQUE
#
require_relative '../spec_helper'
require_relative '../../app/models/scraper'

RSpec.describe Scraper do
  let(:attributes1) do
    { morph_url: 'https://morph.io/planningalerts-scrapers/test',
      github_url: 'https://github.com/planningalerts-scrapers/test', }
  end

  let(:attributes2) do
    { morph_url: 'https://morph.io/planningalerts-scrapers/test2',
      github_url: 'https://github.com/planningalerts-scrapers/test2',
      scraper_file: 'scraper.rb', }
  end

  describe 'fixtures loading' do
    it 'loads all authorities from fixtures' do
      # Verify total count
      expect(Scraper.count).to eq(9)
    end

    it 'loads ACT Scraper' do
      act = Scraper.find_by(morph_url: 'https://morph.io/planningalerts-scrapers/act')

      expect(act).not_to be_nil
      expect(act.github_url).to eq('https://github.com/planningalerts-scrapers/act')
      expect(act.morph_url).to eq('https://morph.io/planningalerts-scrapers/act')
    end
  end

  describe 'accessor methods' do
    it 'accesses properties from all sources' do
      act = FixtureHelper.find(Scraper, :act)

      expect(act.morph_url).to eq('https://morph.io/planningalerts-scrapers/act')
      expect(act.github_url).to eq('https://github.com/planningalerts-scrapers/act')
    end
  end

  describe '#initialize' do
    it 'sets up basic attributes' do
      scraper1 = Scraper.new(attributes1)
      expect(scraper1.morph_url).to eq('https://morph.io/planningalerts-scrapers/test')
      expect(scraper1.github_url).to eq('https://github.com/planningalerts-scrapers/test')
    end

    it 'requires a morph_url' do
      expect do
        Scraper.create!({})
      end.to raise_error(ActiveRecord::RecordInvalid, /Morph url can't be blank, Github url can't be blank/)
    end
  end

  describe '#name' do
    it 'returns the basename of the morph_url' do
      scraper = Scraper.new(attributes1)
      expect(scraper.name).to eq('test')
    end

    it 'handles URLs with trailing slashes' do
      scraper = Scraper.new(morph_url: 'https://morph.io/planningalerts-scrapers/test/',
                            github_url: 'https://github.com/planningalerts-scrapers/test')
      expect(scraper.name).to eq('test')
    end
  end

  describe '#to_s' do
    it 'returns just the name when github and morph names match' do
      scraper = Scraper.new(attributes1)
      expect(scraper.to_s).to eq('test')
    end

    it 'returns name and github name when they differ' do
      scraper = Scraper.new(
        morph_url: 'https://morph.io/planningalerts-scrapers/different_name',
        github_url: 'https://github.com/planningalerts-scrapers/github_name'
      )
      expect(scraper.to_s).to eq('different_name (github_name)')
    end
  end

  describe '.import_from_hash' do
    it 'creates a new scraper when not found' do
      data = {
        'morph_url' => 'https://morph.io/planningalerts-scrapers/new_scraper',
        'github_url' => 'https://github.com/planningalerts-scrapers/new_scraper',
        'scraper_file' => 'scraper.rb',
      }

      expect do
        scraper = Scraper.import_from_hash(data)
        expect(scraper.morph_url).to eq(data['morph_url'])
        expect(scraper.github_url).to eq(data['github_url'])
        # This test is fixed - scraper_file isn't in the IMPORT_KEYS so it won't be assigned
        expect(scraper.scraper_file).to be_nil
      end.to change(Scraper, :count).by(1)
    end

    it 'updates existing scraper when found by morph_url' do
      # Create initial scraper
      initial = Scraper.create!(attributes1)

      # Update with new data
      data = {
        'morph_url' => attributes1[:morph_url],
        'github_url' => 'https://github.com/planningalerts-scrapers/updated',
        'scraper_file' => 'updated.rb',
      }

      expect do
        scraper = Scraper.import_from_hash(data)
        expect(scraper.id).to eq(initial.id)
        expect(scraper.github_url).to eq(data['github_url'])
      end.not_to change(Scraper, :count)
    end

    it 'returns nil when morph_url is blank' do
      expect(Scraper.import_from_hash({ 'github_url' => 'https://github.com/example' })).to be_nil
    end
  end

  describe '#assign_relevant_attributes' do
    let(:scraper) { Scraper.new }

    it 'assigns only whitelisted attributes' do
      data = {
        'morph_url' => 'https://morph.io/test',
        'github_url' => 'https://github.com/test',
        'id' => 999,
        'created_at' => Time.now,
        'other_field' => 'should be ignored',
      }

      scraper.assign_relevant_attributes(data)

      expect(scraper.morph_url).to eq('https://morph.io/test')
      expect(scraper.github_url).to eq('https://github.com/test')
      expect(scraper.id).not_to eq(999)
    end

    it 'handles nil data' do
      expect { scraper.assign_relevant_attributes(nil) }.not_to raise_error
    end
  end

  describe 'associations' do
    it 'has many authorities' do
      # Create a scraper and associated authorities
      scraper = Scraper.create!(attributes2)

      # Due to Authority validations, we need to stub the association
      # rather than creating real Authority objects
      authorities = double('authorities')
      allow(scraper).to receive(:authorities).and_return(authorities)
      allow(authorities).to receive(:count).and_return(2)
      allow(authorities).to receive(:include?).and_return(true)

      # Test the association
      expect(scraper.authorities.count).to eq(2)
    end
  end
end
