# frozen_string_literal: true

# == Schema Information
#
# Table name: coverage_histories
#
#  id                       :integer          not null, primary key
#  authority_count          :integer          default(0), not null
#  broken_authority_count   :integer          default(0), not null
#  broken_population        :integer          default(0), not null
#  extra_broken_authorities :text             default("[]"), not null
#  fixed_count              :integer          default(0), not null
#  fixed_population         :integer          default(0), not null
#  pr_count                 :integer          default(0), not null
#  pr_population            :integer          default(0), not null
#  recorded_on              :date             not null
#  rejected_count           :integer          default(0), not null
#  rejected_population      :integer          default(0), not null
#  total_population         :integer          default(0), not null
#  wayback_url              :string
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#
# Indexes
#
#  index_coverage_histories_on_recorded_on  (recorded_on) UNIQUE
#  index_coverage_histories_on_wayback_url  (wayback_url) UNIQUE
#

# Model to track historical coverage statistics from PlanningAlerts
class CoverageHistory < ApplicationRecord
  validates :recorded_on, presence: true, uniqueness: true
  validates :authority_count, numericality: { greater_than_or_equal_to: 0 }
  validates :broken_authority_count, numericality: { greater_than_or_equal_to: 0 }
  validates :total_population, numericality: { greater_than_or_equal_to: 0 }
  validates :broken_population, numericality: { greater_than_or_equal_to: 0 }
  validates :pr_count, numericality: { greater_than_or_equal_to: 0 }
  validates :pr_population, numericality: { greater_than_or_equal_to: 0 }
  validates :fixed_count, numericality: { greater_than_or_equal_to: 0 }
  validates :fixed_population, numericality: { greater_than_or_equal_to: 0 }
  validates :rejected_count, numericality: { greater_than_or_equal_to: 0 }
  validates :rejected_population, numericality: { greater_than_or_equal_to: 0 }

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

  # Calculate PR coverage percentage (population that will be covered when PRs are accepted)
  def pr_impact_percentage
    return 0 if total_population.zero?

    (pr_population.to_f / total_population * 100).round(1)
  end

  # Calculate percentage of broken authorities with PRs in progress
  def pr_authority_percentage
    return 0 if broken_authority_count.zero?

    (pr_count.to_f / broken_authority_count * 100).round(1)
  end

  # Calculate fixed percentage (population covered by accepted PRs)
  def fixed_percentage
    return 0 if total_population.zero?

    (fixed_population.to_f / total_population * 100).round(1)
  end

  # Calculate rejected percentage (population affected by rejected PRs)
  def rejected_percentage
    return 0 if total_population.zero?

    (rejected_population.to_f / total_population * 100).round(1)
  end

  # Create a record from authorities fetcher results
  def self.create_from_authorities(authorities)
    return nil if authorities.nil? || authorities.empty?

    # Calculate counts and population
    authority_count = authorities.size
    broken_count = authorities.count { |a| a['possibly_broken'] }

    # Sum populations, handling nil values
    total_pop = authorities.sum { |a| a['population'].to_i }
    broken_pop = authorities.select { |a| a['possibly_broken'] }
                            .sum { |a| a['population'].to_i }

    # Create the record for today
    create(
      recorded_on: Date.today,
      authority_count: authority_count,
      broken_authority_count: broken_count,
      total_population: total_pop,
      broken_population: broken_pop
    )
  end

  # Update PR impact metrics - delegates to service
  def self.update_pr_metrics
    PrMetricsService.update_coverage_history_metrics
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
      rec1.pr_count == rec2.pr_count &&
      rec1.pr_population == rec2.pr_population &&
      rec1.fixed_count == rec2.fixed_count &&
      rec1.fixed_population == rec2.fixed_population &&
      rec1.rejected_count == rec2.rejected_count &&
      rec1.rejected_population == rec2.rejected_population
  end
end
