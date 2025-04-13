# frozen_string_literal: true

# == Schema Information
#
# Table name: authorities
#
#  id              :integer          not null, primary key
#  added_on        :date             not null
#  authority_label :string
#  broken_score    :integer
#  delisted_on     :date
#  last_import_log :text
#  last_received   :date
#  median_per_week :integer          default(0), not null
#  month_count     :integer          default(0), not null
#  name            :string           not null
#  population      :integer
#  possibly_broken :boolean          default(FALSE), not null
#  query_error     :string
#  query_owner     :string
#  query_url       :string
#  short_name      :string           not null
#  state           :string(3)
#  total_count     :integer          default(0), not null
#  week_count      :integer          default(0), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  scraper_id      :integer
#
# Indexes
#
#  index_authorities_on_broken_score  (broken_score)
#  index_authorities_on_scraper_id    (scraper_id)
#  index_authorities_on_short_name    (short_name) UNIQUE
#
# Foreign Keys
#
#  scraper_id  (scraper_id => scrapers.id)
#
require 'spec_helper'
require_relative '../../app/models/authority'

RSpec.describe Authority do
  let(:attributes1) { { 'short_name' => 'test1', 'name' => 'Test Authority1' } }

  describe 'fixtures loading' do
    it 'loads all authorities from fixtures' do
      # Verify total count
      expect(Authority.count).to eq(17)
    end

    it 'loads ACT Planning & Land Authority correctly' do
      act = Authority.find_by(short_name: 'act')

      expect(act).not_to be_nil
      expect(act.name).to eq('ACT Planning & Land Authority')
      expect(act.state).to eq('ACT')
      expect(act.population).to eq(454_499)
      expect(act.possibly_broken).to be false

      expect(act.short_name).to eq('act')
      expect(act.scraper.morph_url).to eq('https://morph.io/planningalerts-scrapers/act')
      expect(act.scraper.github_url).to eq('https://github.com/planningalerts-scrapers/act')

      expect(act.week_count).to eq(11)
      expect(act.month_count).to eq(56)
      expect(act.total_count).to eq(8731)
    end

    it 'loads authorities with correct data types' do
      authority = Authority.find_by(short_name: 'bankstown')

      # Test various attribute types
      expect(authority.population).to be_a(Integer)
      expect(authority.possibly_broken).to be_in([true, false])

      # If your fixture dates are properly loaded
      expect(authority.last_received).to be_a(Date) if authority.respond_to?(:last_received) && authority.last_received

      expect(authority.added_on).to be_a(Date) if authority.respond_to?(:added_on) && authority.added_on
    end

    it 'includes authorities that should be working' do
      working_authorities = Authority.where(possibly_broken: false)
      expect(working_authorities.count).to be > 0

      # Check specific working authorities
      expect(working_authorities.pluck(:short_name)).to include('act', 'armidale', 'bankstown', 'baw_baw', 'brimbank')
    end

    it 'includes authorities that are possibly broken' do
      broken_authorities = Authority.where(possibly_broken: true)
      expect(broken_authorities.count).to be > 0

      # Check specific broken authorities
      expect(broken_authorities.pluck(:short_name)).to include('bathurst', 'burwood', 'burdekin', 'banyule',
                                                               'bayside_vic', 'bunbury', 'busselton')
    end
  end

  describe '.all' do
    it 'It reports records' do
      authorities = Authority.active.order(:short_name)
      expect(authorities.size).to eq(16)
      expect(Authority.count).to eq(17)
      expect(authorities.first).to be_a(Authority)
      expect(authorities.first.short_name).to eq('act')
    end
  end

  describe '#initialize' do
    it 'sets up basic attributes' do
      authority1 = Authority.new(attributes1)
      expect(authority1.short_name).to eq('test1')
      expect(authority1.name).to eq('Test Authority1')
      expect(authority1.authorities_url).to eq('https://www.planningalerts.org.au/authorities/test1')
    end

    it 'requires a short_name' do
      expect do
        Authority.create!({})
      end.to raise_error(ActiveRecord::RecordInvalid, /Short name .* Name can't be blank/)
    end
  end

  describe '#to_s' do
    it 'formats name and state correctly' do
      authority = Authority.new(name: 'Test City', state: 'NSW')
      expect(authority.to_s).to eq('Test City (NSW)')
    end

    it 'handles nil state' do
      authority = Authority.new(name: 'Test City', state: nil)
      expect(authority.to_s).to eq('Test City ()')
    end
  end

  describe '#assign_relevant_attributes' do
    it 'returns nil when attributes are nil' do
      authority = Authority.new
      expect(authority.assign_relevant_attributes(nil)).to be_nil
    end

    # it 'assigns scraper when provided and different' do
    #   authority = Authority.new(short_name: 'test')
    #   existing_scraper = Scraper.create!(name: 'old_scraper')
    #   new_scraper = Scraper.create!(name: 'new_scraper')
    #
    #   authority.scraper = existing_scraper
    #
    #   # Mock Scraper.import_from_hash to return the new scraper
    #   allow(Scraper).to receive(:import_from_hash).and_return(new_scraper)
    #
    #   # Should assign the new scraper
    #   authority.assign_relevant_attributes({'name' => 'Test'})
    #   expect(authority.scraper).to eq(new_scraper)
    # end
  end
end
