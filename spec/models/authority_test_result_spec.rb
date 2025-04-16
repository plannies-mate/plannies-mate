# frozen_string_literal: true

# == Schema Information
#
# Table name: authority_test_results
#
#  id              :integer          not null, primary key
#  authority_label :string
#  error_message   :string
#  failed          :boolean          default(FALSE), not null
#  record_count    :integer          default(0)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  authority_id    :integer          not null
#  test_result_id  :integer          not null
#
# Indexes
#
#  idx_authority_test_results                      (test_result_id,authority_id) UNIQUE
#  index_authority_test_results_on_authority_id    (authority_id)
#  index_authority_test_results_on_test_result_id  (test_result_id)
#
# Foreign Keys
#
#  authority_id    (authority_id => authorities.id)
#  test_result_id  (test_result_id => test_results.id)
#
require_relative '../spec_helper'
require_relative '../../app/models/authority_test_result'

RSpec.describe AuthorityTestResult do
  describe 'associations' do
    it 'belongs to a test result' do
      authority_test_result = described_class.new
      expect(authority_test_result).to respond_to(:test_result)
    end

    it 'belongs to an authority' do
      authority_test_result = described_class.new
      expect(authority_test_result).to respond_to(:authority)
    end
  end

  describe 'validations' do
    it 'requires unique authority_id within a test_result' do
      existing = FixtureHelper.find(described_class, :armidale_result)
      duplicate = described_class.new(
        test_result: existing.test_result,
        authority: existing.authority,
        failed: false
      )

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:authority_id]).to include('has already been taken')
    end
  end

  describe 'scopes' do
    before do
      @successful = FixtureHelper.find(described_class, :armidale_result)
      @failed = FixtureHelper.find(described_class, :broken_result)
    end

    it 'filters successful results' do
      results = described_class.successful
      expect(results).to include(@successful)
      expect(results).not_to include(@failed)
    end

    it 'filters failed results' do
      results = described_class.failed
      expect(results).not_to include(@successful)
      expect(results).to include(@failed)
    end
  end

  describe '#improvement?' do
    let(:broken_authority) { FixtureHelper.find(Authority, :bathurst) }
    let(:working_authority) { FixtureHelper.find(Authority, :armidale) }
    let(:test_result) { FixtureHelper.find(TestResult, :test_multiple_atdis_success) }

    it 'returns true when a broken authority is successful in test' do
      result = described_class.new(
        test_result: test_result,
        authority: broken_authority,
        failed: false
      )
      expect(result.improvement?).to be true
    end

    it 'returns false when a working authority is successful in test' do
      result = described_class.new(
        test_result: test_result,
        authority: working_authority,
        failed: false
      )
      expect(result.improvement?).to be false
    end

    it 'returns false when a broken authority fails in test' do
      result = described_class.new(
        test_result: test_result,
        authority: broken_authority,
        failed: true
      )
      expect(result.improvement?).to be false
    end
  end

  describe '#regression?' do
    let(:broken_authority) { FixtureHelper.find(Authority, :bathurst) }
    let(:working_authority) { FixtureHelper.find(Authority, :armidale) }
    let(:test_result) { FixtureHelper.find(TestResult, :test_multiple_atdis_success) }

    it 'returns true when a working authority fails in test' do
      result = described_class.new(
        test_result: test_result,
        authority: working_authority,
        failed: true
      )
      expect(result.regression?).to be true
    end

    it 'returns false when a broken authority fails in test' do
      result = described_class.new(
        test_result: test_result,
        authority: broken_authority,
        failed: true
      )
      expect(result.regression?).to be false
    end

    it 'returns false when a working authority is successful in test' do
      result = described_class.new(
        test_result: test_result,
        authority: working_authority,
        failed: false
      )
      expect(result.regression?).to be false
    end
  end
end
