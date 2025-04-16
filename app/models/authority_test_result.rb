# frozen_string_literal: true

require_relative 'application_record'

# Cache for per-authority test results from morph.io
#
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
class AuthorityTestResult < ApplicationRecord
  belongs_to :test_result
  belongs_to :authority

  # Validations
  validates :authority_id, uniqueness: { scope: :test_result_id }

  scope :successful, -> { where(failed: false) }
  scope :failed, -> { where(failed: true) }

  # Check if this is an improvement over production
  def improvement?
    authority.possibly_broken? && !failed?
  end

  # Check if this is a regression from production
  def regression?
    !authority.possibly_broken? && failed?
  end
end
