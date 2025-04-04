# frozen_string_literal: true

# == Schema Information
#
# Table name: issue_labels
#
#  id          :integer          not null, primary key
#  color       :string
#  default     :boolean          default(FALSE)
#  description :string
#  name        :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_issue_labels_on_name  (name) UNIQUE
#
require_relative '../spec_helper'
require_relative '../../app/models/issue_label'

RSpec.describe IssueLabel do
  describe 'fixtures' do
    it 'loads labels from fixtures' do
      expect(IssueLabel.count).to be > 0
    end

    it 'loads bug label correctly' do
      label = FixtureHelper.find(IssueLabel, :bug)
      
      expect(label).not_to be_nil
      expect(label.name).to eq('bug')
      expect(label.color).to eq('d73a4a')
    end
  end

  describe 'validations' do
    it 'requires name' do
      label = IssueLabel.new(color: 'ff0000')
      expect(label).not_to be_valid
      expect(label.errors[:name]).to include("can't be blank")
    end

    it 'requires unique name' do
      existing = FixtureHelper.find(IssueLabel, :bug)
      
      duplicate = IssueLabel.new(name: existing.name)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:name]).to include('has already been taken')
    end
  end

  describe 'associations' do
    it 'has many issues' do
      label = FixtureHelper.find(IssueLabel, :bug)
      expect(label.issues).to be_an(ActiveRecord::Relation)
    end
  end

  describe '#issues_url' do
    it 'generates a GitHub issues URL for the label' do
      label = FixtureHelper.find(IssueLabel, :bug)
      url = label.issues_url
      
      expect(url).to include('github.com')
      expect(url).to include('label:"bug"')
    end
  end
end
