# frozen_string_literal: true

require 'spec_helper'
require_relative '../../app/services/pr_metrics_service'

RSpec.describe PrMetricsService do
  describe '.calculate_metrics_for_date' do
    # Use fixtures for authorities
    let(:broken_auth) { Fixture.find(Authority, :bathurst) }  # possibly_broken: true
    let(:working_auth) { Fixture.find(Authority, :brimbank) } # possibly_broken: false
    
    # Create test PRs before each test
    before do
      # Clean up any existing test PRs with these titles
      PullRequest.where(title: ['Fix Broken', 'Another Fix', 'Bad Fix', 'Fix Working']).destroy_all
      
      # Create the test PRs
      @open_pr = PullRequest.create!(
        url: 'https://github.com/test/repo/pull/1',
        title: 'Fix Broken',
        created_at: Date.today - 10
      )
      @open_pr.authorities << broken_auth
      
      @accepted_pr = PullRequest.create!(
        url: 'https://github.com/test/repo/pull/2',
        title: 'Another Fix',
        created_at: Date.today - 20,
        closed_at_date: Date.today - 5,
        accepted: true
      )
      @accepted_pr.authorities << broken_auth
      
      @rejected_pr = PullRequest.create!(
        url: 'https://github.com/test/repo/pull/3',
        title: 'Bad Fix',
        created_at: Date.today - 15,
        closed_at_date: Date.today - 8,
        accepted: false
      )
      @rejected_pr.authorities << broken_auth
    end
    
    # Clean up after each test
    after do
      [@open_pr, @accepted_pr, @rejected_pr].each do |pr|
        if pr.persisted?
          pr.authorities.clear
          pr.destroy
        end
      end
    end

    it 'calculates metrics for current date' do
      metrics = described_class.calculate_metrics_for_date(Date.today)

      # Only the open_pr should count as open, only accepted_pr as fixed, only rejected_pr as rejected
      expect(metrics[:pr_count]).to eq(1)
      expect(metrics[:fixed_count]).to eq(1)
      expect(metrics[:rejected_count]).to eq(1)
      
      # Population counts should match the authority fixture values
      expect(metrics[:pr_population]).to eq(broken_auth.population)
      expect(metrics[:fixed_population]).to eq(broken_auth.population)
      expect(metrics[:rejected_population]).to eq(broken_auth.population)
    end

    it 'adjusts metrics for historical dates' do
      # Use a date before any PRs were closed
      historical_date = Date.today - 10

      metrics = described_class.calculate_metrics_for_date(historical_date)

      # On this date, all PRs were open (none were closed yet)
      expect(metrics[:pr_count]).to be >= 2 # All PRs created on or before this date
      expect(metrics[:fixed_count]).to eq(0) # None were fixed yet
      expect(metrics[:rejected_count]).to eq(0) # None were rejected yet
    end

    it 'handles working authorities properly' do
      # Create a PR for a working authority
      working_pr = PullRequest.create!(
        url: 'https://github.com/test/repo/pull/4',
        title: 'Fix Working',
        created_at: Date.today - 5
      )
      
      begin
        working_pr.authorities << working_auth

        metrics = described_class.calculate_metrics_for_date(Date.today)

        # Working authorities shouldn't affect the metrics (they're already working)
        expect(metrics[:pr_count]).to eq(1) # Still just the original broken one
        expect(metrics[:pr_population]).to eq(broken_auth.population) # Only broken authority counted
      ensure
        # Clean up
        if working_pr.persisted?
          working_pr.authorities.clear
          working_pr.destroy
        end
      end
    end
  end

  describe '.update_coverage_history_metrics' do
    # Use a fixture for the history record
    let(:history) { Fixture.find(CoverageHistory, :recent) }

    it 'updates history records with calculated metrics' do
      # Define test metrics that are different from the current values
      test_metrics = {
        pr_count: history.pr_count + 5,
        pr_population: history.pr_population + 50_000,
        fixed_count: history.fixed_count + 3,
        fixed_population: history.fixed_population + 30_000,
        rejected_count: history.rejected_count + 1,
        rejected_population: history.rejected_population + 10_000,
      }

      # Store original values to restore later
      original_values = {
        pr_count: history.pr_count,
        pr_population: history.pr_population,
        fixed_count: history.fixed_count,
        fixed_population: history.fixed_population,
        rejected_count: history.rejected_count,
        rejected_population: history.rejected_population
      }

      begin
        # Mock the calculate_metrics_for_date method
        allow(described_class).to receive(:calculate_metrics_for_date)
          .with(history.recorded_on)
          .and_return(test_metrics)

        # Call the method
        updated = described_class.update_coverage_history_metrics

        # Should update at least one record
        expect(updated).to be > 0

        # Verify the changes
        history.reload
        expect(history.pr_count).to eq(test_metrics[:pr_count])
        expect(history.pr_population).to eq(test_metrics[:pr_population])
        expect(history.fixed_count).to eq(test_metrics[:fixed_count])
        expect(history.fixed_population).to eq(test_metrics[:fixed_population])
        expect(history.rejected_count).to eq(test_metrics[:rejected_count])
        expect(history.rejected_population).to eq(test_metrics[:rejected_population])
      ensure
        # Restore original values
        history.update(original_values)
      end
    end

    it 'does not update unchanged records' do
      # Create metrics that match the current values exactly
      current_values = {
        pr_count: history.pr_count,
        pr_population: history.pr_population,
        fixed_count: history.fixed_count,
        fixed_population: history.fixed_population,
        rejected_count: history.rejected_count,
        rejected_population: history.rejected_population
      }

      # Mock the calculate_metrics_for_date method
      allow(described_class).to receive(:calculate_metrics_for_date)
        .with(history.recorded_on)
        .and_return(current_values)

      # Shouldn't update any records since the values are the same
      updated = described_class.update_coverage_history_metrics
      expect(updated).to eq(0)
    end
  end
end
