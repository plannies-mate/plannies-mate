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
#  error_message   :text
#  record_count    :integer          default(0)
#  status          :string           not null
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
  validates :status, presence: true
  validates :authority_id, uniqueness: { scope: :test_result_id }
  
  # Statuses from morph.io scrape_summary table
  SUCCESSFUL = 'successful'.freeze
  FAILED = 'failed'.freeze
  INTERRUPTED = 'interrupted'.freeze
  
  scope :successful, -> { where(status: SUCCESSFUL) }
  scope :failed, -> { where(status: FAILED) }
  scope :interrupted, -> { where(status: INTERRUPTED) }
  
  # Get status color for UI
  def status_color
    case status
    when SUCCESSFUL
      'green'
    when FAILED
      'red'
    when INTERRUPTED
      'orange'
    else
      'gray'
    end
  end
  
  # Check if this is an improvement over production
  def improvement?
    return false unless authority
    
    # If authority is possibly_broken in production but succeeds in the test
    authority.possibly_broken? && status == SUCCESSFUL
  end
  
  # Check if this is a regression from production
  def regression?
    return false unless authority
    
    # If authority is not possibly_broken in production but fails in the test
    !authority.possibly_broken? && status != SUCCESSFUL
  end
end
