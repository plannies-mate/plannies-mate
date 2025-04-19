# frozen_string_literal: true

require 'time'
require_relative '../spec_helper'
require_relative '../../app/importers/authorities_importer'

RSpec.describe AuthoritiesImporter do
  before do
    @importer = described_class.new
  end

  context 'importing from scratch' do
    before do
      FixtureHelper.clear_database
    end

    it 'imports authorities and scrapers', vcr: { cassette_name: cassette_name('import_authorities_from_scratch') } do
      @importer.import

      authority_count = Authority.count
      expect(authority_count).to be > 170

      scraper_count = Scraper.count
      expect(scraper_count).to be < authority_count
      expect(scraper_count).to be_between(30, 120)
    end

    it 'imports authorities and scrapers, adding whats missing, updating what has changed',
       vcr: { cassette_name: cassette_name('import_authorities_from_scratch_then_redo') } do
      started = Time.now
      @importer.import
      duration_first = Time.now - started

      authority_count = Authority.count
      expect(authority_count).to be > 100

      scraper_count = Scraper.count
      expect(scraper_count).to be_between(30, 50)

      destroyed_scraper = Scraper.first
      puts "Destroying scraper #{destroyed_scraper.name} and associated authorities: #{destroyed_scraper.authorities.pluck(:short_name).inspect}"
      destroyed_authorities = destroyed_scraper.authorities.destroy_all
      destroyed_scraper.destroy

      updated_scraper = Scraper.last
      updated_scraper_name = updated_scraper.name
      puts "Changing scraper name: #{updated_scraper_name} to BadName"
      updated_scraper.update! name: 'BadName'

      updated_authority = updated_scraper.authorities.last
      updated_authority_name = updated_authority.name
      puts "Changing authority name: #{updated_authority_name} to BadName"
      updated_authority.update! name: 'BadName'

      latest_update = [Authority.maximum(:updated_at), Scraper.maximum(:updated_at)].compact.max
      sleep(0.1) while Time.now.to_i <= latest_update.to_i

      # puts 'Authorities:'
      # Authority.order(:short_name).each do |authority|
      #   puts "#{authority.short_name} #{authority.name}#{authority.delisted_on ? ' DELISTED' : ''}"
      # end
      # puts "Scraper: #{Scraper.pluck(:name).sort.to_yaml}"

      puts '-' * 50, 'SECOND IMPORT'
      # Everything should be updated when last checked 8 days ago
      HttpCacheEntry.where.not(last_success_at: nil).update_all(last_success_at: 8.days.ago)
      started = Time.now
      @importer.import
      duration_second = Time.now - started

      # puts "Scraper: #{Scraper.pluck(:name).sort.to_yaml}"

      expect(Authority.count).to eq(authority_count)
      # BadName is not deleted
      expect(Scraper.count).to eq(scraper_count + 1)

      scraper_names = Scraper.pluck(:name)
      authority_names = Authority.pluck(:name)
      expect(destroyed_scraper.name).to be_in(scraper_names)
      expect(destroyed_authorities.first.name).to be_in(authority_names)
      expect(updated_scraper_name).to be_in(scraper_names)
      expect(updated_authority_name).to be_in(authority_names)
      expect('BadName').to be_in(scraper_names)
      expect('BadName').not_to be_in(authority_names)
      puts 'TIMES',
           "First run: #{duration_first}",
           "Second Time: #{duration_second}"
    end
  end
end
