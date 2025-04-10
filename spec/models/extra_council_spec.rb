# frozen_string_literal: true

require_relative '../spec_helper'
require_relative '../../app/models/extra_council'

# Tests ExtraCouncil that has :state, :name, :url, :population_k
RSpec.describe ExtraCouncil do
  describe '.states' do
    it 'includes NSW' do
      expect(described_class.states).to include('NSW')
    end
  end

  describe '.where' do
    it 'returns valid records for NSW' do
      councils = described_class.where(state: 'NSW')
      expect(councils).not_to be_empty

      councils.each do |council|
        expect(council).to be_a(ExtraCouncil)
        expect(council).to be_valid
        expect(council.state).to eq('NSW')
        expect(council.name).to be_present
        expect(council.url).to be_present
        expect(council.population_k).to be_a(Integer)
      end
    end

    describe '#issues' do
      let(:extra_council) { ExtraCouncil.where(state: 'NSW').second }

      context 'when there are no issues matching the council name' do
        it 'returns an empty result' do
          expect(extra_council.issues).to eq([])
        end
      end

      context 'when there are issues with matching names in the system' do
        let!(:more_issue) { Issue.first.tap { |issue| issue.update!(title: "Fix #{extra_council.name}") } }
        let!(:exact_issue) { Issue.last.tap { |issue| issue.update!(title: extra_council.name) } }

        it 'returns issues that have a name similar to the council name' do
          expect(more_issue).to be_a(Issue)
          expect(exact_issue).to be_a(Issue)
          expect(extra_council.issues).to contain_exactly(more_issue, exact_issue)
        end
      end
    end

    describe '#authority' do
      let(:extra_council) { ExtraCouncil.where(state: 'NSW').second }

      context 'when there are no authorities matching the council name' do
        it 'returns nil' do
          expect(extra_council.authority).to be_nil
        end
      end

      context 'when there is an exact match for the name' do
        let!(:authority) do
          Authority.where(state: 'NSW').first.tap { |auth| auth.update!(name: extra_council.name) }
        end

        it 'returns the exact matching authority' do
          expect(authority).to be_a(Authority)
          expect(extra_council.authority).to eq(authority)
        end
      end

      context 'when there are similar names but not exact matches' do
        let!(:best_authority) do
          Authority.where(state: 'NSW').first.tap { |auth| auth.update!(name: "City #{extra_council.name}") }
        end
        let!(:worst_authority) do
          Authority.where(state: 'NSW').last.tap { |auth| auth.update!(name: "City #{extra_council.name} (NSW)") }
        end

        # before do
        #   Authority.where(state: 'NSW').first.update!(name: "City #{extra_council.name}")
        #   Authority.where(state: 'NSW').last.update!(name: "City #{extra_council.name} (NSW)")
        # end

        it 'returns the best matching authority based on normalized name and name size' do
          expect(best_authority).to be_a(Authority)
          expect(worst_authority).to be_a(Authority)

          expect(extra_council.authority).to eq(best_authority)
        end
      end
    end
  end
end
