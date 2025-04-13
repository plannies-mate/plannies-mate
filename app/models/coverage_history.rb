# frozen_string_literal: true

require 'json'

# Model to track historical coverage statistics from PlanningAlerts
#
# == Schema Information
#
# Table name: coverage_histories
#
#  id                     :integer          not null, primary key
#  authority_count        :integer          default(0), not null
#  authority_stats        :json             not null
#  broken_authority_count :integer          default(0), not null
#  broken_population      :integer          default(0), not null
#  recorded_on            :date             not null
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
class CoverageHistory < ApplicationRecord
  # Serialize the JSON column
  # serialize :authority_stats, coder: JSON
  after_initialize :set_default_authority_stats, if: :new_record?

  validates :recorded_on, presence: true, uniqueness: true
  validates :authority_count, numericality: { greater_than_or_equal_to: 0 }
  validates :broken_authority_count, numericality: { greater_than_or_equal_to: 0 }
  validates :total_population, numericality: { greater_than_or_equal_to: 0 }
  validates :broken_population, numericality: { greater_than_or_equal_to: 0 }

  # Calculate percentage of authorities that are broken
  def broken_authority_percentage
    return 0 if authority_count.zero?

    (broken_authority_count.to_f / authority_count * 100).round(1)
  end

  # Calculate percentage of population affected by broken authorities
  def broken_population_percentage
    return 0 if total_population.zero?

    (broken_population.to_f / total_population * 100).round(1)
  end

  # Calculate coverage percentage (population covered by working authorities)
  def coverage_percentage
    return 0 if total_population.zero?

    ((total_population - broken_population).to_f / total_population * 100).round(1)
  end

  # Remove redundant records where three or more consecutive records have identical stats
  def self.optimize_storage
    # Get all records ordered by date
    records = order(:recorded_on).to_a
    return 0 if records.size < 3

    removed_count = 0

    # Process in sliding windows of 3 records
    i = 0
    while i < records.size - 2
      r1 = records[i]
      r2 = records[i + 1]
      r3 = records[i + 2]

      # Check if all three records have identical stats
      if identical_stats?(r1, r2) && identical_stats?(r2, r3)
        # Delete the middle record
        r2.destroy
        removed_count += 1

        # Update our array to reflect the deletion
        records.delete_at(i + 1)
      else
        i += 1
      end
    end

    removed_count
  end

  # Check if two records have identical statistics
  def self.identical_stats?(rec1, rec2)
    rec1.authority_count == rec2.authority_count &&
      rec1.broken_authority_count == rec2.broken_authority_count &&
      rec1.total_population == rec2.total_population &&
      rec1.broken_population == rec2.broken_population &&
      rec1.authority_stats == rec2.authority_stats
    # does NOT compare wayback_url!
  end

  private

  def set_default_authority_stats
    self.authority_stats ||= {}
  end
end
