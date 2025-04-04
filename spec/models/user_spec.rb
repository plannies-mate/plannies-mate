# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id             :integer          not null, primary key
#  avatar_url     :string
#  login          :string           not null
#  site_admin     :boolean          default(FALSE), not null
#  user_view_type :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_users_on_login  (login) UNIQUE
#
require_relative '../spec_helper'
require_relative '../../app/models/user'

RSpec.describe User do
  describe 'fixtures' do
    it 'loads users from fixtures' do
      expect(User.count).to be > 0
    end

    it 'loads user correctly' do
      user = FixtureHelper.find(User, :ianheggie)
      
      expect(user).not_to be_nil
      expect(user.login).to eq('ianheggie')
      expect(user.site_admin).to be false
    end
  end

  describe 'validations' do
    it 'requires login' do
      user = User.new
      expect(user).not_to be_valid
      expect(user.errors[:login]).to include("can't be blank")
    end

    it 'requires unique login' do
      existing = FixtureHelper.find(User, :ianheggie)
      
      duplicate = User.new(login: existing.login)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:login]).to include('has already been taken')
    end
  end

  describe 'associations' do
    it 'has issues through issue_assignees join table' do
      user = FixtureHelper.find(User, :ianheggie_oaf)
      expect(user.issues).to be_an(ActiveRecord::Relation)
    end
  end

  describe '#issues_url' do
    it 'generates a GitHub issues URL for the user' do
      user = FixtureHelper.find(User, :ianheggie)
      url = user.issues_url
      
      expect(url).to include('github.com')
      expect(url).to include('assignee: "ianheggie"')
    end
  end
end
