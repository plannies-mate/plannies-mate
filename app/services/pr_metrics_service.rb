# frozen_string_literal: true

# Service for calculating PR metrics for CoverageHistory
class PrMetricsService
  def self.calculate_metrics_for_date(date)
    # Get all authorities for lookups
    authorities_map = {}
    Authority.all.each do |auth|
      authorities_map[auth.short_name] = {
        population: auth.population,
        possibly_broken: auth.possibly_broken?,
      }
    end

    # Get PRs and their authorities as of the given date
    prs = PullRequest.all.includes(:authorities)

    # Calculate metrics
    metrics = {
      pr_count: 0,
      pr_population: 0,
      fixed_count: 0,
      fixed_population: 0,
      rejected_count: 0,
      rejected_population: 0,
    }

    # For each PR, count its impact based on status and date
    prs.each do |pr|
      # Skip if PR was created after this date
      next if pr.created_at > date

      # Count authorities and population impact
      authorities_impacted = 0
      population_impacted = 0

      pr.authorities.each do |auth|
        auth_info = authorities_map[auth.short_name]
        next unless auth_info && auth_info[:possibly_broken] # Only count if it's broken

        authorities_impacted += 1
        population_impacted += auth_info[:population].to_i
      end

      # Skip if no actual impact (all authorities already working)
      next if authorities_impacted.zero?

      if pr.closed_at_date && pr.closed_at_date <= date
        # PR is closed for this date
        if pr.accepted
          # It was accepted and merged
          metrics[:fixed_count] += authorities_impacted
          metrics[:fixed_population] += population_impacted
        else
          # It was rejected
          metrics[:rejected_count] += authorities_impacted
          metrics[:rejected_population] += population_impacted
        end
      else
        # PR is still open for this date
        metrics[:pr_count] += authorities_impacted
        metrics[:pr_population] += population_impacted
      end
    end

    metrics
  end

  def self.update_coverage_history_metrics
    updated_count = 0

    # Process each history record
    CoverageHistory.find_each do |history|
      metrics = calculate_metrics_for_date(history.recorded_on)

      # Update the history record if any metrics changed
      if history.pr_count != metrics[:pr_count] ||
         history.pr_population != metrics[:pr_population] ||
         history.fixed_count != metrics[:fixed_count] ||
         history.fixed_population != metrics[:fixed_population] ||
         history.rejected_count != metrics[:rejected_count] ||
         history.rejected_population != metrics[:rejected_population]

        history.update(
          pr_count: metrics[:pr_count],
          pr_population: metrics[:pr_population],
          fixed_count: metrics[:fixed_count],
          fixed_population: metrics[:fixed_population],
          rejected_count: metrics[:rejected_count],
          rejected_population: metrics[:rejected_population]
        )

        updated_count += 1
      end
    end

    updated_count
  end
end
