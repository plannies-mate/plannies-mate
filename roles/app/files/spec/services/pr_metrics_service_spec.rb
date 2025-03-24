# frozen_string_literal: true

require 'spec_helper'
require_relative '../../app/services/pr_metrics_service'

RSpec.describe PrMetricsService do
  describe '.calculate_metrics_for_date' do
    let!(:broken_auth) do
      Authority.create!(
        short_name: 'broken',
        name: 'Broken Council',
        url: 'https://example.com/broken',
        possibly_broken: true,
        population: 100_000
      )
    end

    let!(:working_auth) do
      Authority.create!(
        short_name: 'working',
        name: 'Working Council',
        url: 'https://example.com/working',
        possibly_broken: false,
        population: 200_000
      )
    end

    let!(:open_pr) do
      pr = PullRequest.create!(
        url: 'https://github.com/test/repo/pull/1',
        title: 'Fix Broken',
        created_at: Date.today - 10
      )
      pr.authorities << broken_auth
      pr
    end

    let!(:accepted_pr) do
      pr = PullRequest.create!(
        url: 'https://github.com/test/repo/pull/2',
        title: 'Another Fix',
        created_at: Date.today - 20,
        closed_at_date: Date.today - 5,
        accepted: true
      )
      pr.authorities << broken_auth
      pr
    end

    let!(:rejected_pr) do
      pr = PullRequest.create!(
        url: 'https://github.com/test/repo/pull/3',
        title: 'Bad Fix',
        created_at: Date.today - 15,
        closed_at_date: Date.today - 8,
        accepted: false
      )
      pr.authorities << broken_auth
      pr
    end

    it 'calculates metrics for current date' do
      metrics = described_class.calculate_metrics_for_date(Date.today)

      expect(metrics[:pr_count]).to eq(1) # Only open_pr
      expect(metrics[:pr_population]).to eq(100_000)
      expect(metrics[:fixed_count]).to eq(1) # Only accepted_pr
      expect(metrics[:fixed_population]).to eq(100_000)
      expect(metrics[:rejected_count]).to eq(1) # Only rejected_pr
      expect(metrics[:rejected_population]).to eq(100_000)
    end

    it 'adjusts metrics for historical dates' do
      # Check metrics before any PR was closed
      historical_date = Date.today - 10
      metrics = described_class.calculate_metrics_for_date(historical_date)

      expect(metrics[:pr_count]).to eq(3) # All PRs were open then
      expect(metrics[:fixed_count]).to eq(0) # None were fixed yet
      expect(metrics[:rejected_count]).to eq(0) # None were rejected yet
    end

    it 'handles working authorities properly' do
      # Create PR that affects working authority
      pr = PullRequest.create!(
        url: 'https://github.com/test/repo/pull/4',
        title: 'Fix Working',
        created_at: Date.today - 5
      )
      pr.authorities << working_auth

      metrics = described_class.calculate_metrics_for_date(Date.today)

      # Should not count working authority in metrics
      expect(metrics[:pr_count]).to eq(1) # Still just the original broken one
      expect(metrics[:pr_population]).to eq(100_000) # Still just the broken population
    end
  end

  describe '.update_coverage_history_metrics' do
    let!(:history) do
      CoverageHistory.create!(
        recorded_on: Date.today,
        authority_count: 100,
        broken_authority_count: 20,
        total_population: 1_000_000,
        broken_population: 200_000,
        pr_count: 0, # Will be updated
        pr_population: 0,
        fixed_count: 0,
        fixed_population: 0
      )
    end

    it 'updates history records with calculated metrics' do
      metrics = {
        pr_count: 5,
        pr_population: 50_000,
        fixed_count: 3,
        fixed_population: 30_000,
        rejected_count: 1,
        rejected_population: 10_000,
      }

      allow(described_class).to receive(:calculate_metrics_for_date)
        .with(history.recorded_on)
        .and_return(metrics)

      updated = described_class.update_coverage_history_metrics

      expect(updated).to eq(1)

      history.reload
      expect(history.pr_count).to eq(5)
      expect(history.pr_population).to eq(50_000)
      expect(history.fixed_count).to eq(3)
      expect(history.fixed_population).to eq(30_000)
    end

    it 'does not update unchanged records' do
      # Set metrics to match current values
      allow(described_class).to receive(:calculate_metrics_for_date)
        .with(history.recorded_on)
        .and_return({
                      pr_count: 0,
                      pr_population: 0,
                      fixed_count: 0,
                      fixed_population: 0,
                      rejected_count: 0,
                      rejected_population: 0,
                    })

      updated = described_class.update_coverage_history_metrics

      expect(updated).to eq(0)
    end
  end
end
