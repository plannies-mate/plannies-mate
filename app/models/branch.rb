# frozen_string_literal: true

# == Schema Information
#
# Table name: branches
#
#  id              :integer          not null, primary key
#  name            :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  pull_request_id :integer
#  scraper_id      :integer          not null
#
# Indexes
#
#  idx_scraper_branches               (scraper_id,name) UNIQUE
#  index_branches_on_pull_request_id  (pull_request_id)
#  index_branches_on_scraper_id       (scraper_id)
#
# Foreign Keys
#
#  pull_request_id  (pull_request_id => pull_requests.id)
#  scraper_id       (scraper_id => scrapers.id)
#
class Branch < ApplicationRecord
  belongs_to :scraper, required: true
  belongs_to :pull_request, optional: true

  validates :name, presence: true, uniqueness: { scope: :scraper_id }
end
