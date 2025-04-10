# frozen_string_literal: true

# == Schema Information
#
# Table name: coverage_histories
#
#  id                     :integer          not null, primary key
#  authority_count        :integer          default(0), not null
#  broken_authority_count :integer          default(0), not null
#  broken_population      :integer          default(0), not null
#  fixed_count            :integer          default(0), not null
#  fixed_population       :integer          default(0), not null
#  pr_count               :integer          default(0), not null
#  pr_population          :integer          default(0), not null
#  recorded_on            :date             not null
#  rejected_count         :integer          default(0), not null
#  rejected_population    :integer          default(0), not null
#  total_population       :integer          default(0), not null
#  wayback_url            :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_coverage_histories_on_recorded_on  (recorded_on) UNIQUE
#  index_coverage_histories_on_wayback_url  (wayback_url) UNIQUE
#
require_relative '../spec_helper'
require_relative '../../app/models/coverage_history'

RSpec.describe CoverageHistory do
  describe 'validations' do
    it 'requires recorded_on' do
      history = CoverageHistory.new(
        authority_count: 100,
        broken_authority_count: 20,
        total_population: 1_000_000,
        broken_population: 200_000
      )
      expect(history).not_to be_valid
      expect(history.errors[:recorded_on]).to include("can't be blank")
    end

    it 'requires unique recorded_on dates' do
      # Use fixture data
      existing = FixtureHelper.find(CoverageHistory, :recent)

      duplicate = CoverageHistory.new(recorded_on: existing.recorded_on)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:recorded_on]).to include('has already been taken')
    end
  end

  describe 'percentage calculations' do
    it 'calculates broken authority percentage using fixture data' do
      history = FixtureHelper.find(CoverageHistory, :recent)
      expected = (history.broken_authority_count.to_f / history.authority_count * 100).round(1)

      expect(history.broken_authority_percentage).to eq(expected)
    end

    it 'calculates broken population percentage using fixture data' do
      history = FixtureHelper.find(CoverageHistory, :recent)
      expected = (history.broken_population.to_f / history.total_population * 100).round(1)

      expect(history.broken_population_percentage).to eq(expected)
    end

    it 'calculates coverage percentage using fixture data' do
      history = FixtureHelper.find(CoverageHistory, :recent)
      expected = ((history.total_population - history.broken_population).to_f /
        history.total_population * 100).round(1)

      expect(history.coverage_percentage).to eq(expected)
    end

    it 'handles zero values safely' do
      history = CoverageHistory.new(
        recorded_on: Date.today,
        authority_count: 0,
        broken_authority_count: 0,
        total_population: 0,
        broken_population: 0
      )

      expect(history.broken_authority_percentage).to eq(0)
      expect(history.broken_population_percentage).to eq(0)
      expect(history.coverage_percentage).to eq(0)
    end
  end

  describe '.optimize_storage' do
    it 'removes middle records when three consecutive records have identical stats' do
      # Our fixtures have identical1, identical2, and identical3 with the same stats
      expect do
        removed = CoverageHistory.optimize_storage
        expect(removed).to eq(1) # Should remove 1 record
      end.to change(CoverageHistory, :count).by(-1)

      # Check that the middle record was removed
      expect(CoverageHistory.find_by(recorded_on: Date.parse('2024-01-01'))).not_to be_nil
      expect(CoverageHistory.find_by(recorded_on: Date.parse('2024-01-02'))).to be_nil
      expect(CoverageHistory.find_by(recorded_on: Date.parse('2024-01-03'))).not_to be_nil
    end

    it 'does nothing when records are different' do
      # Optimize existing fixtures
      CoverageHistory.optimize_storage
      # Create test records with different values
      CoverageHistory.create!(
        recorded_on: '2023-12-01',
        authority_count: 100,
        broken_authority_count: 20,
        total_population: 1_000_000,
        broken_population: 200_000
      )

      CoverageHistory.create!(
        recorded_on: '2023-12-02',
        authority_count: 101, # Different
        broken_authority_count: 20,
        total_population: 1_000_000,
        broken_population: 200_000
      )

      CoverageHistory.create!(
        recorded_on: '2023-12-03',
        authority_count: 101,
        broken_authority_count: 21, # Different
        total_population: 1_000_000,
        broken_population: 200_000
      )

      expect do
        removed = CoverageHistory.optimize_storage
        expect(removed).to eq(0) # Should not remove any records
      end.not_to change(CoverageHistory, :count)
    end
  end
end
